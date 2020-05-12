final int offset = 15; //Смещение от края окна для красоты

//Список всех листов
List[] ls;
//Индекс текущего листа
int list_i = 0;
//Текущий лист
List l;

//Коофициент перевода миллиметров в пикесели
float min_coof = 1;

//Координата предыдущей и новой выбранной линии. При их сравнении определяется, надо ли перерисовывать линию
int prev_y, new_y;

//Включение/выключение доп опций
boolean show_hint = false;
//boolean show_info = false;

//Отрендеренный лист бумаги фон
PGraphics rendered_list, back_table;
//Надо ли перерисовать лист на экран
boolean rerender_list = false;

//Кнопки действий
Button[] btns;
//Размер кнопки
int bta;

//over - находится ли курсор над кнопкой
//hand - true если курсор установлен на руку, false в ином случае
boolean over, hand;
//Противололожность mouseUnpressed, но обновляется только в конце кадра, поэтому при клике
//на один кадр mouseUnpressed && mousePressed = true
boolean mouseUnpressed; 

//Команды
String[] commands = new String[100];
int com_i, shift, p_com_i;
//Список действий
int[] actions = new int[100]; 

//Режим открытия
boolean mont = false;
//Загружен ли файл
boolean loaded = false;
//Путь последнего файла и его имя
String dir, fname = "";
//Название версии
String ver = "2.110";
