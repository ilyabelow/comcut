

//Инициализация кнопок
void makeButtons() {
  btns = new Button[10];
  //Кнопка для поворота бумаги против часовой стрелки
  btns[0] = new Button( loadShape("turn-left.svg")) {   
    public void action() {
      if (loaded) {
        if (actions[com_i-1] == -3) { //Если предыдущая операция - поворот направо, то она отменяется
          btns[3].action();
        } else { //Иначе просто добавляется операция поворота налево
          push();
          actions[com_i]=-1; //-1 - потому что функция поворота вызывается 1 раз 
          commands[com_i] = (com_i-shift) + ". TURN LEFT";
          com_i++;
          l.rotatePaper();
        }
        renderList();
      }
    }
  };
  //Кнопка поворота по часовой стрелке
  btns[1] = new Button(loadShape("turn-right.svg")) {    
    public void action() {
      if (loaded) {
        if (actions[com_i-1] == -1) {
          btns[3].action();
        } else {
          push();
          actions[com_i]=-3;//-3 - потому что функция поворота вызывается 1 раз 
          commands[com_i] = (com_i-shift) + ". TURN RIGHT";
          com_i++;
          //Поворот направо = 3 поворота налево
          l.rotatePaper();
          l.rotatePaper();
          l.rotatePaper();
        }
        renderList();
      }
    }
  };
  //Кнопка переключения на следующий лист
  btns[2] = new Button(loadShape("clip.svg")) { 
    public void action() {
      if (loaded && ls.length > 1) {
        int new_list = (list_i + 1) % ls.length;
        if (actions[com_i - 1] < 100) { //Если предыдущая команда - не переход с листа на лист
          actions[com_i] = 100 + list_i; //В actions записывается то, с какого листа пришёл
          commands[com_i] = "(взять лист " + (new_list+1) + ")";
          shift++;
          com_i++;
        } else {
          //Иначе новая команда не записывается, переписывается старая чтобы не учитывать предыдущие переходы
          if (actions[com_i-1] - 100 == new_list) { //Если вернулись в исходный лист
            com_i--;
            shift--;
            commands[com_i] = "";
          } else {
            p_com_i = -1; //Не забыть перерисовать команды
            commands[com_i-1] ="(взять лист " + (new_list+1) + ")";
          }
        }    
        //Выбор нового листа
        list_i = new_list;
        l = ls[list_i];
        renderList();
      }
    }
  };
  //Кнопка отмены
  btns[3] = new Button(loadShape("undo.svg")) {
    public void action() {
      if (loaded) {
        if (actions[com_i-1] == -7) {
          commands[com_i-1]= " ";
          actions[com_i-1]=-10; 
          com_i--;
          shift--;
        }
        if (actions[com_i-1]>=0 && actions[com_i-1] < 100) { //Положительные значения действия указывают на индексы линий реза 
          //Установление сторон задетых резом блоков в неразрезанные
          for (int i = 0; i<l.blocks.length; i++) {
            if (l.blocks[i].y1 == l.cl_h[actions[com_i-1]]) {
              l.blocks[i].up_cut = false;
            }
            if (l.blocks[i].y2 == l.cl_h[actions[com_i-1]]) {
              l.blocks[i].down_cut = false;
            }
          }
          //Удаление элемента
          int[] nh= new int[l.cl_h.length-1];
          for (int i = 0; i < actions[com_i-1]; i ++) { //До удаляемого элемента просто копируем все элементы
            nh[i] = l.cl_h[i];
          }
          for (int i = actions[com_i-1]; i < nh.length; i++) { //После удаляемого символа сдвигаем символы на позицию вверх
            nh[i] = l.cl_h[i+1];
          }
          l.cl_h = nh;
          commands[com_i-1] = "";
          actions[com_i-1] = -10; //-10 - пустая команда
          com_i--;
        } else if (actions[com_i-1] == -1 || actions[com_i-1] == -3) {
          l.rotatePaper();
          //Для поворота направо (если предыдщий поворот - налево) нужно просто два раза дополнительно повернуть
          if (actions[com_i-1] == -1) {
            l.rotatePaper();
            l.rotatePaper();
          }
          //Если предыдущая команда - поворот, то просто поворачиваем в противоположном направлении
          commands[com_i-1]="";
          actions[com_i-1]=-10; 
          com_i--;
        } else if (actions[com_i-1] >= 100) {
          list_i = actions[com_i-1]-100;
          l = ls[list_i];
          commands[com_i-1]="";
          actions[com_i-1]=-10; 
          com_i--;
          shift--;
        } else if (actions[com_i-1] <= -100) {
          l.joinPaper(-actions[com_i-1]-100);
          commands[com_i-1]="";
          actions[com_i-1]=-10; 
          com_i--;
          shift--;
        } 
        renderList();
        if (actions[com_i-1] == -5) {
          commands[com_i-1]= " ";
          actions[com_i-1]=-10; 
          com_i--;
        }
      }
    }
  };
  //Кнопка открытия файла
  btns[4] = new Button(loadShape("open-imp.svg")) {
    public void action() {
      mont=false;
      //Файл предлагается открыть из той же папки, откуда был открыт предыдущий
      dir = loadStrings("dir.txt")[0];
      File path = new File(dir);
      //Если папки, из которой происходило открытие последнего файла, не существует, то происходит проверка высших папок. 
      while (!path.exists()) {
        path = new File(path.getParent());
      }
      //Баг, из-за которого после закрытия диалога выбора файла mousePressed = true до нажатия кнопки
      mousePressed = false; 
      selectInput("Выберите CIP файл", "loadFile", path);
    }
  } 
  ;
  //Кнопка сохранения файла
  btns[8] = new Button( loadShape("save.svg")) {
    public void action() {
      if (loaded) {
        //Итоговый файл сохраняется оттуда, откуда был открыт исходный
        File path;//Файл создаётся только для проверки существования? Тупо как-то
        path = new File(dir.substring(0, dir.length()-fname.length()));
        if (!path.exists()) {
          //Если пути не существует, сохраняем в папку скетча
          path = new File(sketchPath());
        }
        saveStrings(path.getAbsolutePath()+"/"+fname.substring(0, fname.lastIndexOf(".") -1 )+"_cut_program.txt", commands);//-1 удаляет букву B или F
      }
    }
  } 
  ;

  //  //Кнопка включения/выключения линий
  //  btns[6] = new Button(new PShape[]{loadShape("hide.svg"), 
  //    loadShape("show.svg")}) {
  //      public void action() {
  //        pic = -(pic-1);
  //  show_lines = !show_lines;
  //  if (loaded) {
  //    renderList();
  //  }
  //}
  //}
  //;

  //Кнопка возвращения листа на исходную позицию
  btns[5] = new Button(loadShape("zoom-back.svg")) {
    public void action() { 
      if (loaded) {
        l.magnitude = 0;
        l.coof = min_coof; 
        l.x=offset;
        l.y=offset;
        for (List.Block b : l.blocks) {
          b.recalculate();
        }
        renderList();
      }
    }
  };
  //Кнопка включения/выключения инфы
  btns[9] = new Button(loadShape("close.svg")) {
    public void action() {
      exit();
    }
  };

  //Кнопка подсказок
  btns[7] = new Button(loadShape("hint.svg")) {
    public void action() {
      show_hint = true;
      over = false;
      image(loadImage("hint.png"), 0, 0);
      fill(0);
      textSize(12);
      text("2017-18 г. ComCut v."+ver+". by ilyabelow. Никакие права не защищены", 0, height-10);
    }
  };
  //Кнопка открытия в режиме монтаж (ВРЕМЕННОЕ РЕШЕНИЕ?)
  btns[6] = new Button(loadShape("open-mon.svg")) {
    public void action() {
      mont = true;
      //Файл предлагается открыть из той же папки, откуда был открыт предыдущий
      dir = loadStrings("dir.txt")[0];
      File path = new File(dir);
      //Если папки, из которой происходило открытие последнего файла, не существует, то происходит проверка высших папок. 
      while (!path.exists()) {
        path = new File(path.getParent());
      }
      //Баг, из-за которого после закрытия диалога выбора файла mousePressed = true до нажатия кнопки
      mousePressed = false; 
      selectInput("Выберите CIP файл", "loadFile", path);
    }
  };

  //Установка координат кнопок
  //Размер кнопки вычисляется так, чтобы они все были равны и поместились вдоль правого края экрана по всей его длине
  bta = (height-offset*(btns.length+1))/btns.length;
  //x координата кнопок
  int bto = width - offset - bta;
  for (int i = 0; i < btns.length; i++) {
    int div = 5;
    //Размер побольше для кнопок открытия
    if (i == 4 || i == 6){
      div = 10;
    }
    btns[i].setCoord(bto, offset*(i+1) + bta*i, div);
  }
}


//Выталкивание листа
void push() {
  //Только когда предыдущая команда - резка
  if (actions[com_i-1]>=0 && actions[com_i-1] < 100) {
    float size = Float.parseFloat(commands[com_i-1].split(" ")[1]);
    float push = 0;
    if (size > 400) {
      push = size/2;
    }
    if (size <= 400 && size > 270) {
      push = size - 200;
    }
    if (size <= 270 && size > 70) {
      push = 70;
    }
    if (push > 0) {
      commands[com_i] = (com_i-shift) + ". BT " + push;
      actions[com_i] = -5;
      com_i++;
    }
  }
}

void mouseDragged() {
  if (loaded && !show_hint) {
    l.x += mouseX -pmouseX;
    l.y += mouseY -pmouseY;
    renderList();
  }
}

void mouseWheel(MouseEvent event) {
  if (loaded && !show_hint) {
    float k1 = exp( l.magnitude);
    l.magnitude = constrain(l.magnitude-0.1*event.getCount(), 0, 2.3); //2 - потому что e^2.3 = 10, минус - потому что колёсико инвертированно\
    float k2 = exp( l.magnitude);
    l.coof = min_coof *k2;
    l.x = mouseX - (int)((k2/k1)*(mouseX - l.x));
    l.y = mouseY - (int)((k2/k1)*(mouseY - l.y));
    for (List.Block b : l.blocks) {
      b.recalculate();
    }
    renderList();
  }
}


void loadFile(File f) {
  if (f == null) { //Файл не выбрал
    return;
  }
  if (!f.getName().substring(f.getName().lastIndexOf(".") + 1).equals("cip")) { //Если открыт не cip файл
    return;
  }
  //Чтобы не шла отрисовка в процессе парсинга
  noLoop();
  //На всякий случай использую абсолютный путь
  dir = f.getAbsolutePath();
  fname = f.getName();
  saveStrings(sketchPath()+"/data/dir.txt", new String[]{dir});//Путь к папке записывается вместе с названием файла, так можно и даже нужно
  //Обнуление всей информации
  commands[0] = "(взять лист 1)";
  actions[0] = -9;
  for (int i = 1; i < commands.length; i++) {
    commands[i] = "";
    actions[i] = -10;
  }
  com_i=1;
  shift = 0;
  ls = new List[]{new List()};
  l = ls[0];
  //Парсинг файла
  parseCIP(f.getAbsolutePath());
  loaded = true;
  surface.setTitle(fname + " - ComCut v."+ver);
  renderList();
  loop();
  //Временное решение для починки таинственного бага в винде
  btns[5].action();
}



//Кнопки интерфейса
abstract class Button {
  int x1, y1, x2, y2, ca; //ca - отступ иконки от края кнопки. Равна одной пятой размера кнопки
  PShape[] icons;
  int state = 3; //0 - курсор не наведён, 1 - курсор наведён, 2 - кнопка нажата
  int pic; //Какая иконка должна показываться

  Button(PShape _icon) {
    icons = new PShape[]{_icon};
  }
  Button(PShape[] _icons) {
    icons = _icons;
  }
  void setCoord(int x, int y, int div) {
    x1 = x;
    y1 = y;
    x2 = x + bta;
    y2 = y + bta;
    ca = bta/div;
  }

  void updateButton() {
    if (mouseX > x1 && mouseX < x2 &&mouseY > y1 && mouseY < y2) {
      over = true;
      if (mousePressed) {
        if (state != 2) {
          state = 2;
          drawButton(235); //Мышь наведена и нажата - тёмно-серый
        }
        if (mousePressed&&mouseUnpressed) { //Чтобы действие выполнилось 1 раз за нажатие
          action();
        }
      } else if (state != 1) {   
        state = 1;
        drawButton(245);//Мышь наведена, но не нажата - светло-серый
      }
    } else if (state != 0) {
      state = 0;      
      drawButton(255);//Мышь не наведена - белый
    }
  }

  void drawButton(int col) {
    noStroke();
    fill(255);
    rect(x1-1, y1-1, x2+1, y2+1);

    stroke(0);
    fill(col);
    rect(x1, y1, x2, y2, 10);
    shape(icons[pic], x1+ca, y1+ca, x2-ca, y2-ca);
  }

  abstract void action();
}
