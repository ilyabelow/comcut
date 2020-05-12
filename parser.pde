void parseCIP(String filepath) { //<>//
  String[] file = loadStrings(filepath);
  int i = 0; //Индекс строки в файле
  //координаты бумаги относительно пластины. Необходимо для пересчёта координат блока, которые тоже даются относительно пластины, а надо относительно листа
  int paper_x = 0, paper_y = 0;
  //Вся информация считывается построчно, при этом проверяется, что за информацию содержит строка,
  //поэтому нет привязки к их порядку, они он всегда один и тот же, но так проще

  //Считывание информации о листе
  while (!file[i].equals("CIP3BeginPreviewImage")) { //*Последняя* строка инфы о листе
    if (!file[i].equals("")) { //Если строка пустая, splitTokens вернёт пустой массив, и line[0] будет давать ошибку
      String[] line = splitTokens(file[i], " []"); //Числа находятся в квадратных скобках и разделены пробелами
      if (line[0].equals("/CIP3AdmPaperTrf")) { //Смещение бумаги
        //5 и 6 - номера нужных чисел в порезанной строк
        paper_x = abs(pttomm(line[5])); 
        paper_y = abs(pttomm(line[6]));
      }
      if (line[0].equals("/CIP3AdmPaperExtent")) { //Размер бумаги
        l.paper_w = pttomm(line[1]);
        l.paper_h = pttomm(line[2]);
        //Высчитывание коофициента перевода миллиметров в пиксели
        min_coof = (float)(height-offset*2)/pttomm(line[1]);
        l.coof = min_coof;
      }
    }
    i++;
  }
  //Пропуск всех лишних строчек между инфой о листе и инфой о блоках
  while (!file[i].equals("CIP3BeginCutData")) {
    i++;
  }
  //Считывание инфы о блоках
  while (!file[i].equals("CIP3EndCutData")) {
    //Новый блок
    if (file[i].equals("CIP3BeginCutBlock")) { 
      //Вся информация о новом блоке
      int block_coord_x = 0, block_coord_y = 0;
      int block_size_x = 0, block_size_y = 0;
      String block_name = "", block_folding="None";
      i++; //Сразу же переходим на следующую строчку после CIP3BeginCutBlock чтобы не терять времени
      while (!file[i].equals("CIP3EndCutBlock")) { //Пока инфа о текущем блоке не кончится
        if (!file[i].equals("")) { //На всякий
          String[] line = splitTokens(file[i], " []");
          //Смещение блока
          if (line[0].equals("/CIP3BlockTrf")) {
            //-координата бумаги - потому что в файле координаты блока даются относительно пластины
            block_coord_x = pttomm(line[5])-paper_x;
            block_coord_y = pttomm(line[6])-paper_y;
          }
          //Размеры блока
          if (line[0].equals("/CIP3BlockSize")) {
            block_size_x = pttomm(line[1]);
            block_size_y = pttomm(line[2]);
          }
          //Имя блока
          if (line[0].equals("/CIP3BlockName")) {
            //Имя блока разделено почему-то на кусоки пробелами
            //нулевой элемент - /CIP3BlockName, последний def, всё между - имя
            for (int t = 1; t < line.length-1; t++) { 
              block_name += line[t] + " ";
            }
          }
          //Начался вложенный блок? оО
          if (line[0].equals("CIP3BeginCutBlock")) {
              block_name += "что-то пошло не так!";
          }
          //Если блок должен складываеться, то он его надо будет ещё поковырять
          if (line[0].equals("/CIP3BlockFoldingProcedure")) {
            block_folding = line[1];
          }
        }
        i++;
      }
      //Инфа о блоке кончилась, значит его можно слава богу добавить
      l.blocks = (List.Block[])append(l.blocks, l.new Block(block_coord_x, block_coord_y, block_size_x, block_size_y, block_name, 's', block_folding));
    }
    i++;
  }
  if (mont) {
    return;
  }
  //Обработка процедур складывания aka фолдингов
  //Название текущего фолдинга
  String folding = "";
  //Является ли блок под определённым индексом "повёрнутым" -
  //внутренние блоки могут быть ориентированны во внешнем по-разному


  while (!file[i].equals("CIP3EndFoldProcedures")) { //Последняя строка раздела с фолдингами
    if (!file[i].equals("")) { // На всякий
      String[] line = splitTokens(file[i], " []");
      //Здесь не предусмотрен внутренний цикл для обработки каждого фолдинка как это было у блоков,
      //потому что сложнее проверять начало описания нового фолдинга, к тому же у него меньше атрибутов
      //Сохраняем политику "строки могут быть в разброс" (может так неправильно?)

      if (line.length >= 2) { // Есть строки длинной в 1 слово, эта проверка предотвращает IndexOutOfBounds
        if (line[1].equals("<<")) { //Только названия фолдинга стоит <<
          folding = line[0];
        }
      }
      //Строка, содержащая размеры блока (ещё раз)
      if (line[0].trim().equals("/CIP3FoldProc")) {
        int fold = -1;
        boolean error = false;
        i++;
        i++;

        if (!file[i].trim().equals("]")) { //= нет операций складывания
          String[] nline = splitTokens(file[i], " ");
          if (!nline[1].equals("/Front") || !nline[2].equals("/Up") || !nline[3].equals("Fold")) { //Остальные аргумент в норме
            error = true;
          }
          fold = pttomm(nline[0]);
          //Проверка на дополнительные резы?
          i++;
          if (!file[i].trim().equals("]")) {
            error = true;
          }
        }
        //Применение настроек фолдинга ко ВСЕМ соответствующим блокам
        for (int ind = 0; ind < l.blocks.length; ind++) {
          List.Block b = l.blocks[ind];          
          if (b.folding.equals(folding)) { //Если у блока именно этот фолдинг
            if (fold != -1) {
              if (b.getWidth() == fold*2) { //<>//
                b.rotation = 'v';
              } else if (b.getHeight() == fold*2) {
                b.rotation = 'h';
              } else { //>_>
                error = true;
              }
            }
            if (error) {
              b.name = b.name + "что-то пошло не так!";
            }
          }
        }
      }
    }
    i++;
  }

  

  //Ширина и высота внутреннего общего блока (мы точно не знаем, что есть что)
  int s1 = 0, s2 = 0; //<>//
  //Почему-то инфа о внутренних блоках написана в разделе о сшивании
  while (!file[i].equals("CIP3EndPrivate")) {//Типа конец информачии о сшивании
    if (!file[i].equals("")) { //На всякий
      String[] line = splitTokens(file[i], " []");
      //Та же схема выявления названия фолдинга
      if (line.length >= 2) {
        if (line[1].equals("<<")) {
          folding = line[0];
        }
      }
      //Считывание высоты и ширины внутреннего блока
      if (line[0].trim().equals("/CutSheetHeight")) { //trim - потому что в начале строки стоит отступ
        s1 = pttomm(line[1]);
      }
      if (line[0].trim().equals("/CutSheetWidth")) {
        s2 = pttomm(line[1]);
      }
      //Если ширина и высота считаны (кривая проверка...)
      if (s1 != 0 && s2 != 0) {




        //Опять таки, перебор всех блоков и проверка, этот ли фолдинг у блока
        for (int ind = 0; ind < l.blocks.length; ind++) {
          List.Block b = l.blocks[ind];
          if (b.folding.equals(folding)) {
            if (b.rotation == 'v') { //Если блок ориентирован горизонтально, рез по центру ВЕРТИКАЛЕН
              //то создаётся два внутренних блока с соответствующими координатами и размерами
              //Блоки находятся справа и слева друг от друга
              //У каждой из половинок - имя родительского блока
              int w = 0, h = 0;
              if (s1*2 < b.getWidth() && s2 < b.getHeight()) {
                w = s1;
                h = s2;
              } else  if (s2*2 < b.getWidth() && s1 < b.getHeight()) {
                w = s2;
                h = s1;
              } else {
                b.name = b.name + "что-то пошло не так!";
              }
              //Разрезание внешнего
              l.blocks[ind] = l.new Block(b.x1, b.y1, b.getWidth()/2, b.getHeight(), "", 'o');
              l.blocks = (List.Block[])append(l.blocks, l.new Block(b.x1+b.getWidth()/2, b.y1, b.getWidth()/2, b.getHeight(), "", 'o'));
              //Согдание внутренних
              l.blocks = (List.Block[])append(l.blocks, l.new Block(b.x1+(b.getWidth()-2*w)/2, b.y1+(b.getHeight()-h)/2, w, h, b.name+" L", 'i'));
              l.blocks = (List.Block[])append(l.blocks, l.new Block(b.x1+(b.getWidth()-2*w)/2+w, b.y1+(b.getHeight()-h)/2, w, h, b.name+" R", 'i'));
            } 
            if (b.rotation == 'h') { //Если вертикально
              //то то же самое, только половинки находятся друг под другом
              int w = 0, h = 0;
              //println("s1 = "+s1+" s2 = "+s2 + " b.getWidth() = " + b.getWidth() + " b.getHeight() = " + b.getHeight());
              if (s1*2 < b.getHeight() && s2 < b.getWidth()) {
                w = s2;
                h = s1;
              } else  if (s2*2 < b.getHeight() && s1 < b.getWidth()) {
                w = s1;
                h = s2;
              } else {
                b.name = b.name + "что-то пошло не так!";
              }

              //Разрезание внешнего блока
              //На старое место ставится одна половинка
              l.blocks[ind] = l.new Block(b.x1, b.y1, b.getWidth(), b.getHeight()/2, "", 'o');
              //А другая добавляется в конец
              l.blocks = (List.Block[])append(l.blocks, l.new Block(b.x1, b.y1+b.getHeight()/2, b.getWidth(), b.getHeight()/2, "", 'o'));
              //При этом у половинок нет имени...

              //Добавление внутренних блоков
              l.blocks = (List.Block[])append(l.blocks, l.new Block(b.x1+(b.getWidth()-w)/2, b.y1+(b.getHeight()-2*h)/2, w, h, b.name+" U", 'i'));
              l.blocks = (List.Block[])append(l.blocks, l.new Block(b.x1+(b.getWidth()-w)/2, b.y1+(b.getHeight()-2*h)/2+h, w, h, b.name+" D", 'i'));
            }
            if (b.rotation == 'n') { //Если внутрынний лист единичный
              int w, h;
              if (s1<b.getHeight() && s2 <b.getWidth()) {
                w = s2;
                h = s1;
              } else {
                w = s1;
                h = s2;
              }
              b.type = 'o';
              l.blocks = (List.Block[])append(l.blocks, l.new Block(b.x1+(b.getWidth()-w)/2, b.y1+(b.getHeight()-h)/2, w, h, b.name, 'i'));
            }
          }
        }
        //Показатель, что фолгинг обработан
        s1 = 0;
        s2 = 0;
      }
    }
    i++;
  }
}
//Перевод пунктов в миллиметры
int pttomm(String pt) {
  return round(float(pt) *2540/72)/10;
}
