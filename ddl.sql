drop table if exists room_type_facility_bind;
drop table if exists room_type_bed_bind;
drop table if exists hotel_payment_type_bind;
drop table if exists hotel_photo_bind;
drop table if exists payment_type;
drop table if exists payment_log;
drop table if exists `order`;
drop table if exists payment_status;
drop table if exists user;
drop table if exists photo;
drop table if exists bed;
drop table if exists facility;
drop table if exists room_status;
drop table if exists room;
drop table if exists room_type_discount;
drop table if exists room_type;
drop table if exists hotel;
drop table if exists locality;

# TODO: добавить хранение соглашения с версионностью и соглашение с правилами гостиницы в заказ

create table locality ( # населённый пункт
  id serial,
  name varchar(255) not null
);

create table hotel ( # гостиница
  id serial,
  name varchar(255) not null,
  description text,
  locality_id bigint unsigned not null,
  address varchar(255) not null,
  contact_info text,
  distance_to_locality_center_in_kilometers float,
  foreign key (locality_id) references locality(id)
);

create table room_type ( # тип гостиничного номера
  id serial,
  hotel_id bigint unsigned not null,
  name varchar(255) not null,
  price_per_day_in_rubles int unsigned not null,
  foreign key (hotel_id) references hotel(id)
);

create table room_type_discount ( # скидка для типа гостиничного номера на конкретную дату
  room_type_id bigint unsigned not null,
  `date` date not null,
  percentage tinyint unsigned not null,
  primary key (room_type_id, `date`),
  foreign key (room_type_id) references room_type(id)
);

create table room ( # гостиничный номер
  id serial,
  room_type_id bigint unsigned not null,
  foreign key (room_type_id) references room_type(id)
);

create table room_status ( # статус гостиничного номера на конкретную дату
  room_id bigint unsigned not null,
  `date` date not null,
  status tinyint unsigned,
  primary key (room_id, `date`),
  foreign key (room_id) references room(id)
);

create table facility ( # удобство
  id serial,
  name varchar(255) not null
);

create table bed ( # тип кровати
  id serial,
  name varchar(255) not null,
  adults_max_capacity tinyint unsigned not null
);

create table photo ( # фото
  id serial,
  url varchar(255) not null
);

create table user ( # пользователь
  id serial,
  login varchar(255) not null, # TODO: добавить уникальность поля login
  hashed_password varchar(255) not null,
  first_name varchar(255),
  last_name varchar(255),
  phone_number varchar(255),
  email_address varchar(255)
);

create table payment_status ( # статус оплаты
  id serial,
  status tinyint unsigned,
  total_price_in_rubles int unsigned not null,
  paid_rubles int unsigned not null default 0
);

create table `order` ( # заказ
  id serial,
  user_id bigint unsigned not null,
  room_id bigint unsigned not null,
  check_in_date date not null,
  check_out_date date not null,
  payment_status_id bigint unsigned not null,
  created_at timestamp not null default current_timestamp,
  foreign key (user_id) references user(id),
  foreign key (room_id) references room(id),
  foreign key (payment_status_id) references payment_status(id)
  # TODO: добавить пожелания заказчика
  # TODO: добавить количество взрослых и количество детей
);

create table payment_log ( # журнал операций оплат
  id serial,
  order_id bigint unsigned not null,
  amount_in_rubles int unsigned not null,
  created_at timestamp not null default current_timestamp,
  foreign key (order_id) references `order`(id)
);

create table payment_type ( # способ оплаты
  id serial,
  name varchar(255)
);

create table hotel_photo_bind ( # фотографии гостиниц
  hotel_id bigint unsigned not null,
  photo_id bigint unsigned not null,
  position tinyint unsigned not null,
  foreign key (hotel_id) references hotel(id),
  foreign key (photo_id) references photo(id),
  primary key (hotel_id, photo_id)
);

create table hotel_payment_type_bind ( # способы оплаты в гостиницах
  hotel_id bigint unsigned not null,
  payment_type_id bigint unsigned not null,
  foreign key (hotel_id) references hotel(id),
  foreign key (payment_type_id) references payment_type(id),
  primary key (hotel_id, payment_type_id)
);

create table room_type_bed_bind ( # типы кроватей для типов гостиничных номеров
  room_type_id bigint unsigned not null,
  bed_id bigint unsigned not null,
  foreign key (room_type_id) references room_type(id),
  foreign key (bed_id) references bed(id),
  primary key (room_type_id, bed_id)
);

create table room_type_facility_bind ( # удобства для типов гостиничных номеров
  room_type_id bigint unsigned not null,
  facility_id bigint unsigned not null,
  foreign key (room_type_id) references room_type(id),
  foreign key (facility_id) references facility(id),
  primary key (room_type_id, facility_id)
);

