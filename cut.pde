void setup() { //<>//
  //Инициализация окна
  size(1200, 800);
  frameRate(30);
  surface.setTitle("ComCut v."+ver);
  surface.setIcon(loadImage("icon.png"));
  //Конфигурация пространств для рисования
  rectMode(CORNERS);
  shapeMode(CORNERS);
  back_table = createGraphics(height, height);
  rendered_list = createGraphics(height, height);
  rendered_list.beginDraw();
  rendered_list.rectMode(CORNERS);
  rendered_list.endDraw();
  //Инициализация интерфейса
  makeButtons();
  //Предварительный рендеринг
    renderBackTable();

  renderBack();
}

void draw() {
  if (show_hint) { 
    if (mousePressed && mouseUnpressed) { //Показ подсказки выключается кликом
      show_hint = false; //Выключить подсказку
      rerender_list = true; //Перерисовать лист заногу, ведь подсказка его перекрывала
      p_com_i = -1; //Перерисовать команды, их тоже накрыло
      renderBack(); //Перерисовать кнопки и затол
      //Делается это сразу тут чтобы случайно дополнительно не нажалась какая-нибудь кнопку
      mouseUnpressed = false;
    }
  } 
  //Тут не else потому что это условие может поменяться внутри if
  if (!show_hint) { //Обновления вообще не происходит если показывается подсказка
    if (loaded) {  //Если файл не загружен, то одновляются только кнопки и курсор (см. ниже)
      //Команды полностью перерисовываются при изменении их количества
      if (p_com_i != com_i) {
        fill(255);
        //Предыдущие команды закрашиваются
        stroke(127); //Этим прямоугольником рисуются вертикульные линии-разделители
        rect(height, -5, width-offset*2-bta, height+5); //+-5 - чтобыне было видно верхних и нижних краёв
        fill(0);
        textSize(15);
        //В колонках по 36 строчек
        int cm = 0, sh = height+offset; //sh - сдвиг текста, каждый раз его долго пересчитывать т.к. формула сложная
        //Левая колонка
        while (!commands[cm].equals("") && cm <= 35) {  
          text(commands[cm], sh, 20+22*cm);
          cm++; //cm - индекс команды
        }
        //Правая колонка
        sh = height+offset+(width-height-bta-offset*3)/2;
        while (!commands[cm].equals("") && cm > 35 && cm <= 71) {  
          text(commands[cm], sh, 20+22*(cm-36));
          cm++;
        }
        p_com_i = com_i;
      }
      //Оптимальный апдейт линий реза
     // if (show_lines) {
        l.checkLines(); //Сперва проверяется, наведён ли курсор на уже готовых линиях реза
        if (new_y != -1) { //Если да
          if (prev_y != new_y) { //Если линия изменилась
            prev_y = new_y;
            image(rendered_list, 0, 0); //Перерендериваем чтобы стереть старую линию
            rerender_list = false;
            l.hover(); //Отрисовка самой линии
          } else { //Если это та же самая линия что и на предыдущем кадре
            l.checkClick(); //То проверяем, кликнута ли эта линия
          }
        } else { //Если нет, то проверяются все блоки
          for (List.Block b : l.blocks) {
            b.checkLines();
            if (new_y != -1) { //Если курсор наведён на край
              if (prev_y != new_y) { //Если линия изменилась
                prev_y = new_y;
                image(rendered_list, 0, 0); //Перерендериваем чтобы стереть старую линию
                rerender_list = false;
                b.hover(); //Отрисовка новой линии
              } else { //Если это та же самая линия что и на предыдущем кадре
                b.checkClick(); //То проверяем, кликнута ли эта линия
              }
              break; //Все последующие блоки не проверяем, т.к. может быть лишь одна линия одновременно
            }
          }
        }
        if (prev_y != -1 && new_y == -1) { //Если раньше была выбранная линия, а теперь нет
          image(rendered_list, 0, 0); //То перерендериваем
          rerender_list = false; //Ещё раз перерендеривать не нужно
          prev_y = -1;
        }
      //}

      if (rerender_list) { //Перерисовывание листа по всем остальным причинам
        image(rendered_list, 0, 0);
        rerender_list = false;
      }
    }
    for (int i = 0; i < btns.length; i++) {  //Обновление кнопок
      btns[i].updateButton();
    }
    if (over) { //Изменение курсора происходит лишь один кадр. Если его менять каждый кадр, он будет моргать
      if (!hand) {
        hand = true;
        cursor(HAND);
      }
    } else {
      if (hand) {
        hand = false;
        cursor(ARROW);
      }
    }
    over = false;
  }
  mouseUnpressed = !mousePressed;   //Обновление mouseUnpressed
}


void renderBackTable() {
  //Фон за листом
  back_table.beginDraw();
  back_table.background(255);
  //Затол
  back_table.rectMode(CORNERS);
  back_table.fill(200);
  back_table.noStroke();
  back_table.rect(offset, 5, height-offset, 10, 1);

  //Шарики
  back_table.fill(246);
  int dist = 50;
  for (int i = 0; i <= height / dist; i++) {
    for (int j = 0; j <= height / dist; j++) {
      back_table.ellipse(i*dist-dist/2, j*dist-dist/2, 10, 10);
    }
  }
  back_table.endDraw();
}



void renderBack() { //Рендеринг фона при запуске рограммы
  background(255);
  image(back_table, 0,0);
  //Кнопки
  fill(255);
  for (int i = 0; i < btns.length; i++) {
    btns[i].drawButton(255);
  }   
  //Линии разделители
  stroke(127);
  line(height, 0, height, height);
  line(width-offset*2-bta, 0, width-offset*2-bta, height);
}


void renderList() { //Рендеринг листа
  rendered_list.beginDraw();
  rendered_list.image(back_table, 0, 0);
  //Лист
  rendered_list.translate(l.x,l.y);
  rendered_list.stroke(0);
  rendered_list.fill(255, 245, 235);
  rendered_list.rect(0, 0, l.paper_w*l.coof, l.paper_h*l.coof);
  //Правильный угол
  if (l.corner) {
    rendered_list.fill(250, 150, 100);
    rendered_list.arc(l.corner_x*l.paper_w*l.coof, l.corner_y*l.paper_h*l.coof, 25, 25, l.corner_rot, l.corner_rot+HALF_PI, PIE);
  }
  //Блоки
  for (List.Block b : l.blocks) {
    if (b.type != 'i') {
      b.drawBlock();
    }
  }
  for (List.Block b : l.blocks) {
    if (b.type == 'i') {
      b.drawBlock();
    }
  }
  //Линии
  //if (show_lines) {
    l.drawLines();
  //}

  rendered_list.endDraw();
  //Автоматическое применение изменений
  rerender_list = true;
}
