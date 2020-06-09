drop database if exists booker;
create database booker character set utf8mb4 collate utf8mb4_unicode_ci;
use booker;

create table region ( # регион
  region_id int unsigned not null primary key,
  name varchar(255) not null
);

create table city ( # город
  id int unsigned not null primary key,
  region_id int unsigned not null,
  name varchar(255) not null,
  foreign key (region_id) references region (region_id)
);

create table user ( # пользователь
  id serial,
  type tinyint unsigned not null, # 1 - менеджер, 2 - клиент
  login varchar(255) not null unique,
  hashed_password varchar(255) not null,
  name varchar(255) not null,
  phone_number varchar(255) not null,
  email_address varchar(255) not null
);

create table hotel ( # гостиница
  id serial,
  name varchar(255) not null,
  description text,
  region_id int unsigned not null,
  city_id int unsigned,
  stars_count tinyint unsigned not null default 0,
  address varchar(255) not null unique,
  phone_number varchar(255) not null,
  email_address varchar(255) not null,
  manager_id bigint unsigned not null unique,
  foreign key (region_id) references region (region_id),
  foreign key (city_id) references city (id),
  foreign key (manager_id) references user (id)
);

create table hotel_attraction ( # важное место (достопримечательность)
  id serial,
  hotel_id bigint unsigned not null,
  name varchar(255) not null,
  foreign key (hotel_id) references hotel (id)
);

create table hotel_rule ( # правило гостиницы
  id serial,
  hotel_id bigint unsigned not null,
  text text not null,
  created_at timestamp not null default current_timestamp,
  foreign key (hotel_id) references hotel (id)
);

create table hotel_room_type ( # тип номера
  id serial,
  hotel_id bigint unsigned not null,
  name varchar(255) not null,
  price int unsigned not null, # цена в день (в рублях)
  rooms_count int unsigned not null,
  available_rooms_count int unsigned not null,
  foreign key (hotel_id) references hotel (id)
);

create table hotel_room_type_discount ( # процент скидки на тип номера на определённую дату
  room_type_id bigint unsigned not null,
  `date` date not null,
  percentage tinyint unsigned not null,
  primary key (room_type_id, `date`),
  foreign key (room_type_id) references hotel_room_type (id)
);

create table facility ( # удобство
  id serial,
  name varchar(255) not null
);

create table bed ( # спальное место
  id serial,
  type tinyint unsigned not null, # 1 - взрослое, 2 - детское
  name varchar(255) not null,
  adults_max_capacity tinyint unsigned not null,
  kids_max_capacity tinyint unsigned not null,
  hotel_id bigint unsigned, # для того, чтобы можно было менеджеру добавить кастомные спальные места
  foreign key (hotel_id) references hotel (id)
);

# TODO: понять, что тут должно быть вместо урла (может имя файла + путь до него)
create table photo ( # фото
  id serial,
  url varchar(255) not null
);

create table hotel_photo ( # фотография гостиницы
  hotel_id bigint unsigned not null,
  photo_id bigint unsigned not null,
  position tinyint unsigned not null,
  is_main bool not null default false,
  foreign key (hotel_id) references hotel (id),
  foreign key (photo_id) references photo (id),
  primary key (hotel_id, photo_id)
);

create table hotel_order ( # заказ на бронирование номера
  id serial,
  hotel_id bigint unsigned not null,
  customer_id bigint unsigned not null,
  check_in_date date not null,
  check_out_date date not null,
  adults_count tinyint unsigned not null,
  kids_count tinyint unsigned not null default 0,
  comment varchar(255),
  cost int unsigned not null, # стоимость заказа (в рублях)
  created_at timestamp not null default current_timestamp,
  foreign key (hotel_id) references hotel (id),
  foreign key (customer_id) references user (id)
);

create table hotel_order_room ( # индекс фактического гостиничного номера заказа
  id serial,
  order_id bigint unsigned not null,
  room_type_id bigint unsigned not null,
  room varchar(255), # nullable т.к. проставляется менеджером после заселения
  foreign key (order_id) references hotel_order (id),
  foreign key (room_type_id) references hotel_room_type (id)
);

create table hotel_order_payment ( # оплата заказа
  id serial,
  order_id bigint unsigned not null,
  amount int unsigned not null, # сколько оплачено (в рублях)
  created_at timestamp not null default current_timestamp,
  foreign key (order_id) references hotel_order (id)
);

create table payment_type ( # способ оплаты
  id serial,
  name varchar(255)
);
insert into payment_type (id, name) values (1, 'Оплата на месте'), (2, 'Предоплата');

create table hotel_payment_type ( # способ оплаты гостиницы
  hotel_id bigint unsigned not null,
  payment_type_id bigint unsigned not null,
  foreign key (hotel_id) references hotel(id),
  foreign key (payment_type_id) references payment_type (id),
  primary key (hotel_id, payment_type_id)
);

create table hotel_room_type_bed ( # тип кровати у типа номера
  room_type_id bigint unsigned not null,
  bed_id bigint unsigned not null,
  foreign key (room_type_id) references hotel_room_type (id),
  foreign key (bed_id) references bed (id),
  primary key (room_type_id, bed_id)
);

create table hotel_room_type_facility ( # удобство у типа номера
  room_type_id bigint unsigned not null,
  facility_id bigint unsigned not null,
  foreign key (room_type_id) references hotel_room_type (id),
  foreign key (facility_id) references facility (id),
  primary key (room_type_id, facility_id)
);

create table hotel_review ( # отзыв о гостинице
  id serial,
  order_id bigint unsigned not null unique,
  summary_text text not null,
  advantages_text text not null,
  disadvantages_text text not null,
  created_at timestamp not null default current_timestamp,
  foreign key (order_id) references hotel_order (id)
);

create table hotel_review_feature ( # характеристка отзыва о гостинице
  id serial,
  name varchar(255) not null
);
insert into hotel_review_feature (id, name) values (1, 'Удобства'), (2, 'Персонал'), (3, 'Расположение'), (4, 'Чистота'), (5, 'Комфорт');

create table hotel_review_feature_rating ( # оценка характеристики отзыва о гостинице
  id serial,
  review_id bigint unsigned not null,
  feature_id bigint unsigned not null,
  rating tinyint unsigned not null,
  foreign key (review_id) references hotel_review (id),
  foreign key (feature_id) references hotel_review_feature (id)
);

create table complaint ( # жалоба клиента на гостиницу
  id serial,
  customer_id bigint unsigned not null,
  hotel_id bigint unsigned not null,
  text text not null,
  created_at timestamp not null default current_timestamp,
  foreign key (customer_id) references user (id),
  foreign key (hotel_id) references hotel (id)
);




create table service_category ( # категория услуг
  id serial,
  name varchar(255)
);
insert into service_category (id, name) values (1, 'Еда'), (2, 'Напитки'), (3, 'Горячие блюда'), (4, 'Русская кухня');

create table service ( # услуга
  id serial,
  type tinyint unsigned not null, # 1 - еда/напитки, 2 - сервис
  hotel_id bigint unsigned not null,
  name varchar(255) not null,
  category_id bigint unsigned not null,
  has_alcohol bool,
  nutrition_proteins float unsigned, # пищевая ценность (на 100 г продукта) - белки (в граммах)
  nutrition_fats float unsigned, # пищевая ценность (на 100 г продукта) - жиры (в граммах)
  nutrition_carbs float unsigned, # пищевая ценность (на 100 г продукта) - углеводы (в граммах)
  calories smallint unsigned, # энергетическая ценность (на 100 г продукта) - калории (в ккал)
  waiting_time smallint unsigned, # время ожидания услуги (в минутах)
  execution_time smallint unsigned, # время выполнения услуги (в минутах)
  foreign key (hotel_id) references hotel (id),
  foreign key (category_id) references service_category (id)
);

create table service_portion ( # порция услуги (или опция)
  id serial,
  service_id bigint unsigned not null,
  is_option bool not null default false,
  size int unsigned not null,
  unit varchar(255) not null, # TODO: может тут nullable?
  price bigint unsigned not null, # цена порции (в копейках)
  foreign key (service_id) references service (id)
);

create table ingredient ( # ингредиент
  id serial,
  name varchar(255) not null,
  hotel_id bigint unsigned, # для того, чтобы можно было менеджеру добавить кастомные ингредиенты (по аналогии с bed)
  foreign key (hotel_id) references hotel (id)
);

create table service_ingredient ( # ингредиент услуги
  service_id bigint unsigned not null,
  ingredient_id bigint unsigned not null,
  foreign key (service_id) references service (id),
  foreign key (ingredient_id) references ingredient (id),
  primary key (service_id, ingredient_id)
);

create table service_availability ( # доступность услуги
  service_id bigint unsigned not null,
  start smallint unsigned not null, # начало отрезка времени суток (в минутах)
  end smallint unsigned not null, # конец отрезка времени суток (в минутах)
  foreign key (service_id) references service (id),
  primary key (service_id, start, end)
);

create table service_order ( # заказ услуги
  id serial,
  ordered_service_id bigint unsigned not null,
  order_id bigint unsigned not null,
  room varchar(255) not null, # индекс гостиничного номера из hotel_order_room по order_id TODO: может быть тут nullable? Ведь не всегда услуга предоставляется в номер. Или всегда?
  portion_id bigint unsigned not null,
  portions_amount smallint unsigned not null,
  customer_comment text,
  manager_comment text,
  created_at timestamp not null default current_timestamp,
  foreign key (ordered_service_id) references service (id),
  foreign key (order_id) references hotel_order (id),
  foreign key (portion_id) references service_portion (id)
);

create table service_order_option ( # опция услуги в заказе услуги
  order_id bigint unsigned not null,
  option_id bigint unsigned not null,
  amount smallint unsigned not null,
  foreign key (order_id) references service_order (id),
  foreign key (option_id) references service_portion (id),
  primary key (order_id, option_id)
);

create table service_photo ( # фотография услуги
  service_id bigint unsigned not null,
  photo_id bigint unsigned not null,
  position tinyint unsigned not null,
  is_main bool not null default false,
  foreign key (service_id) references service (id),
  foreign key (photo_id) references photo (id),
  primary key (service_id, photo_id)
);
