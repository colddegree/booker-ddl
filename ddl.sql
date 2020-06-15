drop database if exists service;
drop database if exists hotel;
drop database if exists common;
create database common character set utf8mb4 collate utf8mb4_unicode_ci;
create database hotel character set utf8mb4 collate utf8mb4_unicode_ci;
create database service character set utf8mb4 collate utf8mb4_unicode_ci;

create table common.region ( # регион
  region_id int unsigned not null primary key,
  name varchar(255) not null
);

create table common.city ( # город региона
  id int unsigned not null primary key,
  region_id int unsigned not null,
  name varchar(255) not null,
  foreign key (region_id) references common.region (region_id)
);

create table common.district ( # район города
  id int unsigned not null primary key,
  city_id int unsigned not null,
  name varchar(255) not null,
  foreign key (city_id) references common.city (id)
);

create table common.user ( # пользователь
  id serial primary key,
  type tinyint unsigned not null, # 1 - менеджер, 2 - клиент
  login varchar(255) not null unique,
  hashed_password varchar(255) not null,
  full_name varchar(255), # ФИО
  phone_number varchar(255),
  email_address varchar(255)
);

# TODO: понять, что тут должно быть вместо урла (может имя файла + путь до него)
create table common.photo ( # фото
  id serial primary key,
  url varchar(255) not null
);




create table hotel.hotel ( # гостиница
  id serial primary key,
  name varchar(255) not null,
  description text,
  stars_count tinyint unsigned not null default 0,
  phone_number varchar(255) not null,
  email_address varchar(255) not null,
  manager_id bigint unsigned not null unique,
  region_id int unsigned not null,
  city_id int unsigned,
  district_id int unsigned,
  address varchar(255) not null unique,
  foreign key (manager_id) references common.user (id),
  foreign key (region_id) references common.region (region_id),
  foreign key (city_id) references common.city (id),
  foreign key (district_id) references common.district (id)
);

create table hotel.favorite ( # избранная гостиница клиента
  customer_id bigint unsigned not null,
  hotel_id bigint unsigned not null,
  foreign key (customer_id) references common.user (id),
  foreign key (hotel_id) references hotel.hotel (id),
  primary key (customer_id, hotel_id)
);

create table hotel.attraction ( # важное место (достопримечательность)
  id serial primary key,
  hotel_id bigint unsigned not null,
  name varchar(255) not null,
  foreign key (hotel_id) references hotel.hotel (id)
);

create table hotel.rule ( # правило гостиницы
  id serial primary key,
  hotel_id bigint unsigned not null,
  text text not null,
  created_at timestamp not null default current_timestamp,
  foreign key (hotel_id) references hotel.hotel (id)
);

create table hotel.room_type ( # тип номера
  id serial primary key,
  hotel_id bigint unsigned not null,
  name varchar(255) not null,
  price int unsigned not null, # цена в день (в рублях)
  with_free_cancellation bool not null default false,
  rooms_count int unsigned not null,
  available_rooms_count int unsigned not null,
  foreign key (hotel_id) references hotel.hotel (id)
);

create table hotel.bed ( # спальное место
  id serial primary key,
  type tinyint unsigned not null, # 1 - взрослое, 2 - детское
  name varchar(255) not null,
  adults_max_capacity tinyint unsigned not null,
  kids_max_capacity tinyint unsigned not null,
  hotel_id bigint unsigned, # для того, чтобы можно было менеджеру добавить кастомные спальные места
  foreign key (hotel_id) references hotel.hotel (id)
);

create table hotel.room_type_bed ( # тип кровати у типа номера
  room_type_id bigint unsigned not null,
  bed_id bigint unsigned not null,
  foreign key (room_type_id) references hotel.room_type (id),
  foreign key (bed_id) references hotel.bed (id),
  primary key (room_type_id, bed_id)
);

create table hotel.facility ( # удобство
  id serial primary key,
  name varchar(255) not null
);

create table hotel.room_type_facility ( # удобство у типа номера
  room_type_id bigint unsigned not null,
  facility_id bigint unsigned not null,
  foreign key (room_type_id) references hotel.room_type (id),
  foreign key (facility_id) references hotel.facility (id),
  primary key (room_type_id, facility_id)
);

create table hotel.room_type_discount ( # процент скидки на тип номера на определённую дату
  room_type_id bigint unsigned not null,
  `date` date not null,
  percentage tinyint unsigned not null,
  primary key (room_type_id, `date`),
  foreign key (room_type_id) references hotel.room_type (id)
);

create table hotel.order ( # заказ на бронирование номера
  id serial primary key,
  hotel_id bigint unsigned not null,
  customer_id bigint unsigned not null,
  customer_full_name varchar(255) not null, # ФИО клиента
  customer_phone_number varchar(255) not null,
  customer_email_address varchar(255) not null,
  check_in_date date not null,
  check_out_date date not null,
  adults_count tinyint unsigned not null,
  kids_count tinyint unsigned not null default 0,
  comment varchar(255),
  cost int unsigned not null, # стоимость заказа (в рублях)
  created_at timestamp not null default current_timestamp,
  is_canceled bool not null default false,
  foreign key (hotel_id) references hotel.hotel (id),
  foreign key (customer_id) references common.user (id)
);

create table hotel.order_kid ( # ребёнок в заказе
  id serial primary key,
  order_id bigint unsigned not null,
  age tinyint unsigned not null,
  foreign key (order_id) references hotel.order (id)
);

create table hotel.order_room ( # индекс фактического гостиничного номера заказа
  id serial primary key,
  order_id bigint unsigned not null,
  room_type_id bigint unsigned not null,
  room varchar(255), # nullable т.к. проставляется менеджером после заселения
  foreign key (order_id) references hotel.order (id),
  foreign key (room_type_id) references hotel.room_type (id)
);

create table hotel.order_payment ( # оплата заказа
  id serial primary key,
  order_id bigint unsigned not null,
  rubles_count int unsigned not null, # сколько оплачено (в рублях)
  created_at timestamp not null default current_timestamp,
  foreign key (order_id) references hotel.order (id)
);

create table hotel.payment_type ( # способ оплаты
  id serial primary key,
  name varchar(255)
);
insert into hotel.payment_type (id, name) values (1, 'Оплата на месте'), (2, 'Предоплата');

create table hotel.payment_type_bind ( # способ оплаты гостиницы
  hotel_id bigint unsigned not null,
  payment_type_id bigint unsigned not null,
  foreign key (hotel_id) references hotel.hotel(id),
  foreign key (payment_type_id) references hotel.payment_type (id),
  primary key (hotel_id, payment_type_id)
);

create table hotel.review ( # отзыв о гостинице
  id serial primary key,
  order_id bigint unsigned not null unique,
  summary_text text not null,
  advantages_text text,
  disadvantages_text text,
  created_at timestamp not null default current_timestamp,
  foreign key (order_id) references hotel.order (id)
);

create table hotel.review_feature ( # характеристка отзыва о гостинице
  id serial primary key,
  name varchar(255) not null
);
insert into hotel.review_feature (id, name) values (1, 'Удобства'), (2, 'Персонал'), (3, 'Расположение'), (4, 'Чистота');

create table hotel.review_feature_rating ( # оценка характеристики отзыва о гостинице
  id serial primary key,
  review_id bigint unsigned not null,
  feature_id bigint unsigned not null,
  rating tinyint unsigned not null,
  foreign key (review_id) references hotel.review (id),
  foreign key (feature_id) references hotel.review_feature (id)
);

create table hotel.complaint ( # жалоба клиента на гостиницу
  id serial primary key,
  customer_id bigint unsigned not null,
  hotel_id bigint unsigned not null,
  text text not null,
  created_at timestamp not null default current_timestamp,
  foreign key (customer_id) references common.user (id),
  foreign key (hotel_id) references hotel.hotel (id)
);

create table hotel.photo ( # фотография гостиницы
  hotel_id bigint unsigned not null,
  photo_id bigint unsigned not null,
  position tinyint unsigned not null,
  is_main bool not null default false,
  foreign key (hotel_id) references hotel.hotel (id),
  foreign key (photo_id) references common.photo (id),
  primary key (hotel_id, photo_id)
);




create table service.category ( # категория услуг
  id serial primary key,
  name varchar(255) not null,
  hotel_id bigint unsigned, # для того, чтобы можно было менеджеру добавить кастомные категории
  foreign key (hotel_id) references hotel.hotel (id)
);
insert into service.category (name) values ('Еда'), ('Напитки'), ('Горячие блюда'), ('Русская кухня');

create table service.service ( # услуга
  id serial primary key,
  type tinyint unsigned not null, # 1 - еда/напитки, 2 - сервис
  hotel_id bigint unsigned not null,
  name varchar(255) not null,
  description text,
  category_id bigint unsigned,
  has_alcohol bool,
  nutrition_proteins float unsigned, # пищевая ценность (на 100 г продукта) - белки (в граммах)
  nutrition_fats float unsigned, # пищевая ценность (на 100 г продукта) - жиры (в граммах)
  nutrition_carbs float unsigned, # пищевая ценность (на 100 г продукта) - углеводы (в граммах)
  calories smallint unsigned, # энергетическая ценность (на 100 г продукта) - калории (в ккал)
  waiting_time smallint unsigned, # время ожидания услуги (в минутах)
  execution_time smallint unsigned, # время выполнения услуги (в минутах)
  price bigint unsigned, # цена услуги (в копейках), только для услуг типа "сервис"
  foreign key (hotel_id) references hotel.hotel (id),
  foreign key (category_id) references service.category (id)
);

create table service.portion_unit ( # единица измерения порции
  id serial primary key,
  name varchar(255) not null,
  hotel_id bigint unsigned, # для того, чтобы можно было менеджеру добавить кастомные единицы измерения порций (по аналогии с hotel.bed)
  foreign key (hotel_id) references hotel.hotel (id)
);

create table service.portion ( # порция услуги (или опция)
  id serial primary key,
  service_id bigint unsigned not null,
  is_option bool not null default false,
  option_name varchar(255),
  size int unsigned not null,
  unit varchar(255) not null, # значение из service.portion_unit.name (чтобы при изменении значения не менялось в порции)
  price bigint unsigned not null, # цена порции (в копейках)
  foreign key (service_id) references service.service (id)
);

create table service.ingredient ( # ингредиент
  id serial primary key,
  name varchar(255) not null,
  hotel_id bigint unsigned, # для того, чтобы можно было менеджеру добавить кастомные ингредиенты (по аналогии с hotel.bed)
  foreign key (hotel_id) references hotel.hotel (id)
);

create table service.ingredient_bind ( # ингредиент услуги
  service_id bigint unsigned not null,
  ingredient_id bigint unsigned not null,
  foreign key (service_id) references service.service (id),
  foreign key (ingredient_id) references service.ingredient (id),
  primary key (service_id, ingredient_id)
);

create table service.availability ( # доступность услуги
  service_id bigint unsigned not null,
  start smallint unsigned not null, # начало отрезка времени суток (в минутах)
  end smallint unsigned not null, # конец отрезка времени суток (в минутах)
  foreign key (service_id) references service.service (id),
  primary key (service_id, start, end)
);

create table service.photo ( # фотография услуги
  service_id bigint unsigned not null,
  photo_id bigint unsigned not null,
  position tinyint unsigned not null,
  is_main bool not null default false,
  foreign key (service_id) references service.service (id),
  foreign key (photo_id) references common.photo (id),
  primary key (service_id, photo_id)
);

create table service.order ( # заказ услуги
  id serial primary key,
  ordered_service_id bigint unsigned not null,
  order_id bigint unsigned not null,
  room varchar(255) not null, # индекс гостиничного номера из hotel.order_room по order_id (у нас все услуги предоставляются в номер)
  portion_id bigint unsigned, # выставляется только для услуг типа "еда/напитки"
  portions_count smallint unsigned, # выставляется только для услуг типа "еда/напитки"
  must_be_served_at datetime not null, # дата и время когда должна быть оказана услуга клиенту
  customer_comment text,
  manager_comment text,
  created_at timestamp not null default current_timestamp,
  status tinyint not null, # статус заказа услуги: 1 - ожидает выполнения, 2 - в процессе выполнения, 3 - выполнено, 4 - отказано
  foreign key (ordered_service_id) references service.service (id),
  foreign key (order_id) references hotel.order (id),
  foreign key (portion_id) references service.portion (id)
);

create table service.order_option ( # опция услуги в заказе услуги
  order_id bigint unsigned not null,
  option_id bigint unsigned not null,
  options_count smallint unsigned not null,
  foreign key (order_id) references service.order (id),
  foreign key (option_id) references service.portion (id),
  primary key (order_id, option_id)
);
