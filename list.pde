class List {
  //Блоки
  Block[] blocks = new Block[]{};
  //Размеры бумаги
  int paper_w, paper_h;
  //Линии реза
  int[] cl_h= new int[]{};
  int[] cl_v= new int[]{};
  int corner_x = 1;
  int corner_y = 0;
  boolean corner = true;
  float corner_rot = HALF_PI;
  int was_line; //Какая по счёту линия была выбрана
  int x=offset, y=offset;
  float magnitude = 0;
  float coof = min_coof;

  void rotatePaper() {
    //Поворот блоков
    int x1, y1, x2, y2;
    boolean buf;
    Block b;
    for (int i = 0; i < blocks.length; i++) {
      b = blocks[i];
      x1 = b.x1;
      x2 = b.x2;
      y1 = b.y1;
      y2 = b.y2;
      //Не спрашивайте, как это работает, на бумажке нарисовал как это будет, и вот - работает
      b.x1 = y1;
      b.y1 = paper_w - x2;
      b.x2 = y2;
      b.y2 = paper_w - x1;
      //Поворот порезанных сторон
      buf =  b.up_cut;
      b.up_cut = b.right_cut;
      b.right_cut = b.down_cut;
      b.down_cut = b.left_cut;
      b.left_cut = buf;

      b.recalculate();
    }
    b = null;
    //Поворот линий реза
    //Переворачиваем сами линии
    for (int i = 0; i < cl_v.length; i++) {
      cl_v[i] = paper_w - cl_v[i];
    }
    //Меняем местами вертикальные и горизонтальные
    int[] old = cl_h;
    cl_h = cl_v;
    cl_v = old;
    //Пересортируем массив горизонтальных чтобы они опять были отсортированными
    old = cl_h.clone();
    for (int i = 0; i < cl_h.length; i++) {
      cl_h[i] = old[cl_h.length - i - 1];
    }
    //Поворот правильного угла
    if (corner_x == 1 && corner_y == 0) {
      corner_x = 0;
      corner_rot = 0;
    } else if (corner_x == 1 && corner_y == 1) {
      corner_y = 0;
      corner_rot = HALF_PI;
    } else if (corner_x == 0 && corner_y == 1) {
      corner_x = 1;
      corner_rot = PI;
    } else {
      corner_y = 1;
      corner_rot = PI + HALF_PI;
    }
    //Поворот всего листа
    int c = paper_w;
    paper_w = paper_h;
    paper_h = c;
  }

  //Проверка, если ли линия, на которую наведён курсор
  void checkLines() {
    for (int i = 0; i < cl_h.length; i++) {
      if (mouseY >= cl_h[i]*coof+y-3 && mouseY<= cl_h[i]*coof+y +3&& mouseX>=x && mouseX <=x+ paper_w*coof) {
        new_y = cl_h[i];
        return;
      }
    }
    new_y = -1;
  }

  //Донести до сознания линии, что на неё действительно навли курсор
  void hover() {
    stroke(0, 0, 250);
    line(x, new_y*coof+y, min(paper_w*coof+x, height), new_y*coof+y);
  }

  //Проверка, кликнута ли линия
  void checkClick() {
    if (mouseUnpressed && mousePressed && new_y != 0 && new_y != paper_h) {
      for (int i = 0; i < cl_h.length; i++) {
        if (cl_h[i] == new_y) {
          splitPaper(i);
          break;
        }
      }
    }
  }

  //Отрисовка линий на лист
  void drawLines() {
    //Горизонтальные
    for (int i = 0; i < cl_h.length; i++) {
      if (cl_h[i] == 0 || cl_h[i] == paper_h) { //Если линии с краю, то они синие
        rendered_list.stroke(0, 0, 250);
      } else {
        rendered_list.stroke(0, 250, 0);
      }
      rendered_list.line(0, cl_h[i]*coof, paper_w*coof, cl_h[i]*coof);
    }
    //Вертикальные
    for (int i = 0; i < cl_v.length; i++) {
      if (cl_v[i] == 0 || cl_v[i] == paper_w) {
        rendered_list.stroke(0, 0, 250);
      } else {
        rendered_list.stroke(0, 250, 0);
      }
      rendered_list.line(cl_v[i]*coof, 0, cl_v[i]*coof, paper_h*coof);
    }
  }

  //Разделение листа на две части
  void splitPaper(int ind) {
    int line = cl_h[ind]; //Координата линии реза, по которой разделяется лист

    int upper = 0, lower = 0;
    for (int i = 0; i < blocks.length; i++) { //Подсчёт, сколько блоков выше и ниже линии реза
      if (blocks[i].y1 >= line) { 
        lower++;
      } else {
        upper++;
      }
      //Если линия реза проходит через наружний блок (который хоть и можно резать), то делить листы запрещается. Норм?..
      if (blocks[i].y1 < line && blocks[i].y2 > line) { 
        return;
      }
    }

    if (lower > 0 && upper > 0) { //Разделение проиходит только если блоки есть по обе стороны от линии
      List nl = new List(); //Новый лист
      Block[] ublocks = new Block[]{}; //Блоки, остающиеся на текущем листе. Массив переделывается для того, чтобы избавиться от старых блоков
      for (int i = 0; i < blocks.length; i++) {
        if (blocks[i].y1 >= line) { //Если блок ниже линии реза
          //Поднимаем блок (у текущего листа! так при его готовым можно легко перенести на наовый лист)
          blocks[i].y1 -= line;
          blocks[i].y2 -= line;
          //Перенос блока в новый лист
          nl.blocks = (Block[])append(nl.blocks, nl.new Block(blocks[i]));
        } else {
          ublocks = (Block[])append(ublocks, blocks[i]); //Копируем блок в новые лист
        }
      }
      //Обновление старых блоков
      blocks = ublocks;
      //Вертикальны линии реза копируются просто
      nl.cl_v = new int[cl_v.length];
      for (int i = 0; i < cl_v.length; i++) {
        nl.cl_v[i] =  cl_v[i];
      }
      int[] ucl_h = new int[ind+1]; //Верхние линии
      int[] dcl_h = new int[cl_h.length - ind]; //Нижние линии
      for (int i = 0; i <= ind; i++) {
        ucl_h[i] = cl_h[i];
      }
      for (int i = 0; i < dcl_h.length; i++) {
        dcl_h[i] = cl_h[i+ind] - line;
      }
      //Обновление линий реза
      cl_h = ucl_h;
      nl.cl_h = dcl_h;
      //Обновление размеров
      nl.paper_w = paper_w;
      nl.paper_h = paper_h - line;
      paper_h = line;
      //Обновление угла
      if (corner_y == 0) {
        nl.corner = false;
      } else {
        corner = false;
        nl.corner_x = corner_x;
        nl.corner_y = 1;
        nl.corner_rot = corner_rot;
      }
      //Наконец, добавление нового листа
      ls = (List[])append(ls, nl);
      //Добавление команды
      push();
      actions[com_i] = -100-(ls.length-1); //Записываем индекс отложенного листа
      commands[com_i] = "(отложить лист " + ls.length + ")";
      shift++;
      com_i++;
      renderList();
    }
  }

  //Объединение двух некогда разделённых листов
  void joinPaper(int paper) {
    //paper - id отложенного, дочернего листа (в момент вызова функции текущим листом является родительский)
    //Дочерний лист, блоки которого присоединится к текущему
    List add = ls[paper];
    //Новый список листов необходим чтобы сдвинуть листы в дырку от отменяемого листа
    List[] nls = new List[ls.length-1];
    for (int i = 0; i < paper; i++) {
      nls[i] = ls[i];
    }
    for (int i = paper+1; i < ls.length; i++) {
      nls[i-1] = ls[i];
    }
    ls = nls;
    for (int i = 0; i < add.blocks.length; i++) {
      //Опущение листов на прежний уровень
      add.blocks[i].y1 += paper_h;
      add.blocks[i].y2 += paper_h;
      //Перенос блока в текущий лист
      blocks = (Block[])append(blocks, new Block(add.blocks[i]));
    }
    //Опущение горизонтальных линий реза на прежний уровень (как и с блоками)
    for (int i = 1; i < add.cl_h.length; i++) {
      cl_h = (int[])append(cl_h, add.cl_h[i] + paper_h);
    }
    //Если главный урол находился в дочернем листе
    if (add.corner) {
      corner = true;
      corner_x = add.corner_x;
      corner_y = 1;
      corner_rot = add.corner_rot;
    }
    //Увеличение высоты родительского листа
    paper_h += add.paper_h;
  }


  //Блок
  class Block { 
    int x1, y1, x2, y2;
    int coof_x1, coof_y1, coof_x2, coof_y2;
    String name, info;
    boolean up_cut, down_cut, left_cut, right_cut;
    boolean allowed; //Можно ли делать выбранный рез
    char type; //s = single, i = inner, o = outer

    //Данные, нужные при парсинге
    //Под поворотом подразумевается ориентация линии-разделителя
    char rotation = 'n'; //v = vertcal, h = horizontal, n = none (внутренний блок один)
    String folding;

    //Конструктор создания блока
    Block(int x, int y, int w, int h, String _name, char _type) { 
      folding = "None";
      x1 = x;
      y1 = y;
      x2 = x + w;
      y2 = y + h;
      name = _name;
      type = _type;
      float real_h = h/10;
      float real_w = w/10;
      if (real_w-(int)real_w == 0) { //Уничтожение нуля после запятой
        info = (int)real_w+ "x";
      } else {
        info = real_w+ "x";
      }
      if (real_h-(int)real_h == 0) {
        info += (int)real_h;
      } else {
        info += real_h;
      }
      recalculate();
    }



    Block(int x, int y, int w, int h, String _name, char _type, String _folding) { 
      x1 = x;
      y1 = y;
      x2 = x + w;
      y2 = y + h;
      name = _name;
      type = _type;
      folding = _folding;

      float real_h = h/10;
      float real_w = w/10;
      if (real_w-(int)real_w == 0) { //Уничтожение нуля после запятой
        info = (int)real_w+ "x";
      } else {
        info = real_w+ "x";
      }
      if (real_h-(int)real_h == 0) {
        info += (int)real_h;
      } else {
        info += real_h;
      }
      recalculate();
    }

    //Конструктор копирования блока. Необходим для переноса блоков с одного листа на другой
    Block(Block b) { 
      x1 = b.x1;
      y1 = b.y1;
      x2 = b.x2;
      y2 = b.y2;
      recalculate();
      name = b.name;
      info = b.info;
      up_cut = b.up_cut;
      down_cut = b.down_cut;
      left_cut = b.left_cut;
      right_cut = b.right_cut;
      type = b.type;
      folding = b.folding;
    }

    //Пересчёт размеров блоков в пикселях. Нужен при переменещии блоков с листа на лист
    void recalculate() {
      coof_x1 = (int)(x1*coof);
      coof_y1 = (int)(y1*coof);
      coof_x2 = (int)(x2*coof);
      coof_y2 = (int)(y2*coof);
    }

    void drawBlock() {
      if (type == 's') {
        rendered_list.fill(250, 200, 150);
      }
      if (type == 'i') {
        rendered_list.fill(250, 185, 145);
      }
      if (type == 'o') {
        rendered_list.fill(250, 220, 180);
      }
      rendered_list.rect(coof_x1, coof_y1, coof_x2, coof_y2);
      rendered_list.fill(0);
      //if (show_info) {
      rendered_list.textSize(11);
      rendered_list.text(info, ((coof_x1+coof_x2)-info.length()*7.5)/2, (coof_y1+coof_y2)/2 + 15);
      //}
      rendered_list.textSize(13);
      //name.length()*5.7 - костыльная замета textWidth(), потому что по какой-то причине он выдаёт другое значение при рендериге при открытии файла
      rendered_list.text(name, ((coof_x1+coof_x2)-name.length()*5.7)/2, (coof_y1+coof_y2)/2);
    }


    void checkLines() {
      if (mouseX >= coof_x1+x && mouseX <= coof_x2+x) {
        if (!up_cut) { //Если сторона уже порезана, то не рассматриваем её
          if  (mouseY >= coof_y1-2+y && mouseY<= coof_y1+4+y) {
            new_y = y1;
            return;
          }
        }
        if (!down_cut) {
          if (mouseY >= coof_y2-4 +y&& mouseY <= coof_y2+2+y) {
            new_y = y2;
            return;
          }
        }
      }
      new_y = -1;
    }


    void hover() {
      int coof_y = (int)(new_y*coof);
      //Зелёная линия на весь лист
      stroke(0, 255, 0);
      line(x, coof_y+y, min(paper_w*coof+x, height), coof_y+y);
      //Можно ли делать рез
      allowed = true;
      for (int i = 0; i<blocks.length; i++) { 
        if (blocks[i].y1 < new_y && blocks[i].y2 > new_y && blocks[i].type != 'o') { //Блок стоит на пути линии реза, при этом резать через наружние блоки разрешается
          //Красная линия над блоком
          stroke(255, 0, 0);
          line(blocks[i].coof_x1+x, coof_y+y, min(blocks[i].coof_x2+x, height), coof_y+y);
          allowed = false;
        }
      }
    }

    void checkClick() {
      if (mousePressed && mouseUnpressed && allowed) { //Мышь нажата
        int coof_y= (int)(new_y*coof);
        //"Сохранение линии" реза на листе. Можно конечно просто перерисовать весь лист, но так куда проще
        rendered_list.beginDraw();
        rendered_list.stroke(0, 255, 0);
        rendered_list.line(x, coof_y+y, paper_w*coof+x, coof_y+y);
        rendered_list.endDraw();
        cl_h = (int[])append(cl_h, new_y); //Добавление новой линии реза
        int oi = 0; //Индекс, где окажется новая линия реза
        //Сортировка вставкой
        for (int i = cl_h.length-1; i > 0; i--) {
          if (cl_h[i]<cl_h[i-1]) {
            int buf = cl_h[i];
            cl_h[i] = cl_h[i-1];
            cl_h[i-1] = buf;
          } else {
            oi = i;
            break;
          }
        }
        //Запись реза в команды
        actions[com_i] = oi;
        if (oi == 0) {
          commands[com_i] = (com_i-shift) + ". " + cl_h[oi]/10.0;
        } else {
          commands[com_i] = (com_i-shift) + ". " + (cl_h[oi]-cl_h[oi-1])/10.0;
        }
        com_i++;
        //Обозначение соответствующей стороны текущего блока как порезанную
        if (new_y == y1) {
          up_cut = true;
        } else {
          down_cut = true;
        }
        //Обозначение сторон всех задетых блоков как порезанные
        for (int i = 0; i<blocks.length; i++) {
          if (blocks[i].y1 == new_y) {
            blocks[i].up_cut = true;
          }
          if (blocks[i].y2 == new_y) {
            blocks[i].down_cut = true;
          }
        }
        prev_y = -1;
      }
    }

    int getWidth() {
      return x2-x1;
    }
    int getHeight() {
      return y2-y1;
    }
  }
}
