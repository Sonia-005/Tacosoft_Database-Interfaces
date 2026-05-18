-- ============================================================
--  TACOSOFT - Sistema de Punto de Venta
--  "El Sinaloense" - Cadena de Taquerias
-- ============================================================

USE master;
GO


IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'TacoSoft')
BEGIN
    CREATE DATABASE TacoSoft;
END
GO

USE TacoSoft;
GO


IF OBJECT_ID('Sucursales', 'U') IS NOT NULL DROP TABLE Sucursales;
GO

CREATE TABLE Sucursales (
    sucursal_id   INT IDENTITY(1,1) PRIMARY KEY,
    nombre        VARCHAR(100)  NOT NULL,
    direccion     VARCHAR(200)  NOT NULL,
    ciudad        VARCHAR(100)  NOT NULL,
    telefono      VARCHAR(20)   NOT NULL,
    estatus       VARCHAR(10)   NOT NULL DEFAULT 'activa'
        CONSTRAINT chk_sucursal_estatus CHECK (estatus IN ('activa', 'cerrada'))
);
GO

IF OBJECT_ID('Categorias', 'U') IS NOT NULL DROP TABLE Categorias;
GO

CREATE TABLE Categorias (
    categoria_id  INT IDENTITY(1,1) PRIMARY KEY,
    nombre        VARCHAR(100) NOT NULL,
    descripcion   VARCHAR(300)
);
GO


IF OBJECT_ID('Productos', 'U') IS NOT NULL DROP TABLE Productos;
GO

CREATE TABLE Productos (
    producto_id   INT IDENTITY(1,1) PRIMARY KEY,
    nombre        VARCHAR(150)     NOT NULL,
    descripcion   VARCHAR(400),
    categoria_id  INT              NOT NULL,
    precio        DECIMAL(10, 2)   NOT NULL,
    costo         DECIMAL(10, 2)   NOT NULL,
    estatus       VARCHAR(15)      NOT NULL DEFAULT 'disponible'
        CONSTRAINT chk_producto_estatus CHECK (estatus IN ('disponible', 'no disponible')),
    CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_id)
        REFERENCES Categorias(categoria_id)
);
GO

IF OBJECT_ID('Empleados', 'U') IS NOT NULL DROP TABLE Empleados;
GO

CREATE TABLE Empleados (
    empleado_id       INT IDENTITY(1,1) PRIMARY KEY,
    nombre_completo   VARCHAR(150)    NOT NULL,
    telefono          VARCHAR(20)     NOT NULL,
    puesto            VARCHAR(20)     NOT NULL
        CONSTRAINT chk_empleado_puesto CHECK (puesto IN ('cajero', 'cocinero', 'repartidor', 'gerente')),
    sucursal_id       INT             NOT NULL,
    salario_quincenal DECIMAL(10, 2)  NOT NULL,
    fecha_ingreso     DATE            NOT NULL,
    estatus           VARCHAR(10)     NOT NULL DEFAULT 'activo'
        CONSTRAINT chk_empleado_estatus CHECK (estatus IN ('activo', 'inactivo')),
    CONSTRAINT fk_empleado_sucursal FOREIGN KEY (sucursal_id)
        REFERENCES Sucursales(sucursal_id)
);
GO

IF OBJECT_ID('Clientes', 'U') IS NOT NULL DROP TABLE Clientes;
GO

CREATE TABLE Clientes (
    cliente_id      INT IDENTITY(1,1) PRIMARY KEY,
    nombre          VARCHAR(150)  NOT NULL,
    telefono        VARCHAR(20)   NOT NULL,
    correo          VARCHAR(200),
    ciudad          VARCHAR(100)  NOT NULL,
    fecha_registro  DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE)
);
GO

IF OBJECT_ID('Pedidos', 'U') IS NOT NULL DROP TABLE Pedidos;
GO

CREATE TABLE Pedidos (
    pedido_id     INT IDENTITY(1,1) PRIMARY KEY,
    sucursal_id   INT           NOT NULL,
    empleado_id   INT           NOT NULL,
    cliente_id    INT           NULL,   
    fecha_hora    DATETIME      NOT NULL DEFAULT GETDATE(),
    tipo_pedido   VARCHAR(15)   NOT NULL
        CONSTRAINT chk_pedido_tipo CHECK (tipo_pedido IN ('en local', 'para llevar', 'a domicilio')),
    estatus       VARCHAR(15)   NOT NULL DEFAULT 'pendiente'
        CONSTRAINT chk_pedido_estatus CHECK (estatus IN ('pendiente', 'preparando', 'listo', 'entregado', 'cancelado')),
    total         DECIMAL(10, 2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_pedido_sucursal  FOREIGN KEY (sucursal_id)  REFERENCES Sucursales(sucursal_id),
    CONSTRAINT fk_pedido_empleado  FOREIGN KEY (empleado_id)  REFERENCES Empleados(empleado_id),
    CONSTRAINT fk_pedido_cliente   FOREIGN KEY (cliente_id)   REFERENCES Clientes(cliente_id)
);
GO


IF OBJECT_ID('DetallePedido', 'U') IS NOT NULL DROP TABLE DetallePedido;
GO

CREATE TABLE DetallePedido (
    detalle_id      INT IDENTITY(1,1) PRIMARY KEY,
    pedido_id       INT             NOT NULL,
    producto_id     INT             NOT NULL,
    cantidad        INT             NOT NULL CONSTRAINT chk_detalle_cantidad CHECK (cantidad > 0),
    precio_unitario DECIMAL(10, 2)  NOT NULL,   
    subtotal        AS (cantidad * precio_unitario) PERSISTED,
    CONSTRAINT fk_detalle_pedido   FOREIGN KEY (pedido_id)   REFERENCES Pedidos(pedido_id),
    CONSTRAINT fk_detalle_producto FOREIGN KEY (producto_id) REFERENCES Productos(producto_id)
);
GO


IF OBJECT_ID('Promociones', 'U') IS NOT NULL DROP TABLE Promociones;
GO

CREATE TABLE Promociones (
    promocion_id  INT IDENTITY(1,1) PRIMARY KEY,
    nombre        VARCHAR(150)    NOT NULL,
    descripcion   VARCHAR(400),
    descuento_pct DECIMAL(5, 2)   NOT NULL
        CONSTRAINT chk_promo_descuento CHECK (descuento_pct > 0 AND descuento_pct <= 100),
    fecha_inicio  DATE            NOT NULL,
    fecha_fin     DATE            NOT NULL,
    CONSTRAINT chk_promo_fechas CHECK (fecha_fin >= fecha_inicio)
);
GO

IF OBJECT_ID('PromocionProductos', 'U') IS NOT NULL DROP TABLE PromocionProductos;
GO

CREATE TABLE PromocionProductos (
    promocion_id  INT NOT NULL,
    producto_id   INT NOT NULL,
    PRIMARY KEY (promocion_id, producto_id),
    CONSTRAINT fk_pp_promocion FOREIGN KEY (promocion_id) REFERENCES Promociones(promocion_id),
    CONSTRAINT fk_pp_producto  FOREIGN KEY (producto_id)  REFERENCES Productos(producto_id)
);
GO

INSERT INTO Sucursales (nombre, direccion, ciudad, telefono, estatus) VALUES
('El Sinaloense Culiacán',    'Blvd. Zapata 1250, Col. Chapultepec',        'Culiacán',  '667-123-4567', 'activa'),
('El Sinaloense Mazatlán',    'Av. Rafael Buelna 340, Col. Tellería',        'Mazatlán',  '669-234-5678', 'activa'),
('El Sinaloense Los Mochis',  'Blvd. Jiquilpan 890, Col. Centro',           'Los Mochis','668-345-6789', 'activa'),
('El Sinaloense Guasave',     'Calle Ángel Flores 210, Col. El Palmar',     'Guasave',   '687-456-7890', 'activa');
GO


INSERT INTO Categorias (nombre, descripcion) VALUES
('Tacos',    'Tacos artesanales con tortilla de maíz hecha a mano'),
('Burritos', 'Burritos de harina con rellenos generosos'),
('Bebidas',  'Aguas frescas, refrescos y bebidas calientes'),
('Postres',  'Dulces tradicionales sinaloenses'),
('Extras',   'Complementos, salsas y guarniciones');
GO

INSERT INTO Productos (nombre, descripcion, categoria_id, precio, costo, estatus) VALUES
-- Tacos (cat 1)
('Taco de Birria',        'Taco dorado bañado en consomé con cilantro y cebolla',    1,  45.00, 18.00, 'disponible'),
('Taco de Carne Asada',   'Taco de tortilla de maíz con carne asada norteña',        1,  40.00, 15.00, 'disponible'),
('Taco de Carnitas',      'Carnitas de cerdo con salsa verde y cebolla morada',       1,  38.00, 14.00, 'disponible'),
('Taco de Camarón',       'Camarón al mojo de ajo con chile güero y aguacate',       1,  55.00, 22.00, 'disponible'),
('Taco de Frijoles',      'Taco vegetariano con frijoles refritos y queso cotija',   1,  28.00,  9.00, 'disponible'),
-- Burritos (cat 2)
('Burrito de Carne',      'Burrito grande de harina con carne asada y queso',        2,  75.00, 28.00, 'disponible'),
('Burrito de Pollo',      'Burrito de pollo al chipotle con arroz y frijoles',       2,  70.00, 25.00, 'disponible'),
('Burrito Vegetariano',   'Burrito de verduras salteadas, queso y pico de gallo',    2,  65.00, 22.00, 'disponible'),
('Burrito de Camarón',    'Burrito de camarón al ajillo con guacamole',              2,  85.00, 35.00, 'disponible'),
-- Bebidas (cat 3)
('Agua de Horchata',      'Horchata tradicional con canela, 500 ml',                 3,  22.00,  5.00, 'disponible'),
('Agua de Jamaica',       'Jamaica fresca sin azúcar añadida, 500 ml',              3,  20.00,  4.00, 'disponible'),
('Refresco',              'Coca-Cola, Pepsi o Sprite en lata 355 ml',               3,  25.00,  9.00, 'disponible'),
('Café de Olla',          'Café negro tradicional endulzado con piloncillo',         3,  30.00,  6.00, 'disponible'),
-- Postres (cat 4)
('Cajeta con Nieve',      'Nieve de vainilla con cajeta artesanal de Culiacán',      4,  45.00, 14.00, 'disponible'),
('Churros con Chocolate', 'Churros crujientes con chocolate caliente para dippear',  4,  40.00, 12.00, 'disponible'),
('Flan de Cajeta',        'Flan casero bañado en cajeta sinaloense',                4,  35.00, 10.00, 'disponible'),
-- Extras (cat 5)
('Guacamole',             'Aguacate fresco con jitomate, limón y cilantro',          5,  30.00,  8.00, 'disponible'),
('Salsa Roja Extra',      'Salsa de chile de árbol tatemado, porción extra',         5,  10.00,  2.00, 'disponible'),
('Orden de Queso',        'Queso asadero derretido, orden adicional',               5,  20.00,  6.00, 'disponible'),
('Tortillas Extras',      'Tres tortillas de maíz hechas a mano',                  5,  12.00,  3.00, 'no disponible');
GO


INSERT INTO Empleados (nombre_completo, telefono, puesto, sucursal_id, salario_quincenal, fecha_ingreso, estatus) VALUES
-- Culiacán (sucursal 1)
('Mario Alberto Lizárraga Félix',   '667-111-0001', 'gerente',    1, 8500.00, '2020-03-15', 'activo'),
('Karla Yolanda Rojo Soto',         '667-111-0002', 'cajero',     1, 4200.00, '2021-06-01', 'activo'),
('Ernesto Valdez Palomino',         '667-111-0003', 'cocinero',   1, 4800.00, '2021-06-01', 'activo'),
('Lorena Guadalupe Meza Torres',    '667-111-0004', 'repartidor', 1, 3900.00, '2022-01-10', 'activo'),
-- Mazatlán (sucursal 2)
('Patricia Inés Verdugo Higuera',   '669-222-0001', 'gerente',    2, 8500.00, '2019-11-20', 'activo'),
('Jesús Manuel Cota Beltrán',       '669-222-0002', 'cajero',     2, 4200.00, '2022-03-14', 'activo'),
('Rosa Elena Ibarra Quintero',      '669-222-0003', 'cocinero',   2, 4800.00, '2021-09-05', 'activo'),
-- Los Mochis (sucursal 3)
('Rogelio Armenta Gastélum',        '668-333-0001', 'gerente',    3, 8500.00, '2020-07-01', 'activo'),
('Fabiola Denisse Chávez Ríos',     '668-333-0002', 'cajero',     3, 4200.00, '2023-01-15', 'activo'),
('Benito Salazar Morales',          '668-333-0003', 'cocinero',   3, 4800.00, '2022-08-20', 'activo'),
-- Guasave (sucursal 4)
('Leticia Ojeda Valenzuela',        '687-444-0001', 'gerente',    4, 8500.00, '2021-02-28', 'activo'),
('Héctor Ramón Corrales Lugo',      '687-444-0002', 'cajero',     4, 4200.00, '2023-05-10', 'activo'),
('Alejandra Yépez Castro',          '687-444-0003', 'cocinero',   4, 4800.00, '2022-11-01', 'inactivo');
GO


INSERT INTO Clientes (nombre, telefono, correo, ciudad, fecha_registro) VALUES
('Juan Pablo Burgos Medina',    '667-500-1111', 'juan.burgos@gmail.com',    'Culiacán',  '2024-01-15'),
('Sandra Elisa Félix Montoya',  '667-500-2222', 'sandrafelix@hotmail.com',  'Culiacán',  '2024-02-20'),
('Roberto Celis Angulo',        '669-500-3333', 'r.celis@outlook.com',      'Mazatlán',  '2024-03-05'),
('Diana Laura Páez Gámez',      '669-500-4444', 'dianapez@gmail.com',       'Mazatlán',  '2024-04-10'),
('Carlos Humberto Meza Lugo',   '668-500-5555', 'carlosmeza@gmail.com',     'Los Mochis','2024-05-18'),
('Miriam Judith Acosta Villa',  '668-500-6666', 'miriam.acosta@yahoo.com',  'Los Mochis','2024-06-22'),
('Gustavo Adolfo Robles Salas', '687-500-7777', 'gustavorobles@gmail.com',  'Guasave',   '2024-07-30'),
('Verónica Irene Tirado Ruiz',  '687-500-8888', 'veronica.tirado@gmail.com','Guasave',   '2024-08-14'),
('Martín Aurelio Leyva Ponce',  '667-500-9999', 'martinleyva@hotmail.com',  'Culiacán',  '2024-09-02'),
('Gabriela Sofía Urias Reyes',  '669-500-0000', 'gabyurias@gmail.com',      'Mazatlán',  '2024-10-19');
GO

INSERT INTO Promociones (nombre, descripcion, descuento_pct, fecha_inicio, fecha_fin) VALUES
('Promo Verano 2025',    'Descuento en tacos y bebidas durante el verano',          15.00, '2025-06-01', '2025-08-31'),
('Semana del Burrito',   'Todos los burritos con descuento especial',               20.00, '2026-05-10', '2026-05-17'),
('Descuento Clásico',    'Promo permanente en productos básicos del menú',          10.00, '2026-01-01', '2026-12-31');
GO

INSERT INTO PromocionProductos VALUES (1,1),(1,2),(1,10),(1,11);
INSERT INTO PromocionProductos VALUES (2,6),(2,7),(2,8),(2,9);
INSERT INTO PromocionProductos VALUES (3,5),(3,12),(3,18),(3,20);
GO

-- Pedido 1 - Culiacán, cajero Karla, cliente 1, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (1, 2, 1, '2026-04-01 12:30:00', 'en local', 'entregado', 160.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(1, 1, 2, 45.00), (1, 10, 2, 22.00), (1, 17, 1, 30.00);

-- Pedido 2 - Culiacán, cajero Karla, público, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (1, 2, NULL, '2026-04-01 13:15:00', 'para llevar', 'entregado', 198.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(2, 6, 2, 75.00), (2, 12, 2, 25.00), (2, 18, 2, 10.00), (2, 15, 1, 40.00) ;

-- Pedido 3 - Mazatlán, cajero Jesús, cliente 3, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (2, 6, 3, '2026-04-02 14:00:00', 'en local', 'entregado', 175.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(3, 4, 2, 55.00), (3, 11, 2, 20.00), (3, 19, 1, 20.00), (3, 16, 1, 35.00);

-- Pedido 4 - Mazatlán, cajero Jesús, cliente 4, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (2, 6, 4, '2026-04-02 19:00:00', 'a domicilio', 'entregado', 240.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(4, 9, 2, 85.00), (4, 12, 2, 25.00), (4, 14, 1, 45.00);

-- Pedido 5 - Los Mochis, cajero Fabiola, cliente 5, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (3, 9, 5, '2026-04-03 12:00:00', 'en local', 'entregado', 135.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(5, 2, 2, 40.00), (5, 3, 1, 38.00), (5, 17, 1, 30.00);

-- Pedido 6 - Guasave, cajero Héctor, público, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (4, 12, NULL, '2026-04-03 13:45:00', 'para llevar', 'entregado', 100.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(6, 5, 2, 28.00), (6, 13, 1, 30.00), (6, 18, 2, 10.00);

-- Pedido 7 - Culiacán, cajero Karla, cliente 2, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (1, 2, 2, '2026-04-10 11:00:00', 'en local', 'entregado', 270.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(7, 1, 3, 45.00), (7, 7, 1, 70.00), (7, 10, 2, 22.00), (7, 15, 1, 40.00);

-- Pedido 8 - Culiacán, cajero Karla, público, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (1, 2, NULL, '2026-04-10 20:30:00', 'a domicilio', 'entregado', 185.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(8, 6, 1, 75.00), (8, 4, 1, 55.00), (8, 11, 2, 20.00), (8, 19, 1, 20.00);

-- Pedido 9 - Mazatlán, cajero Jesús, cliente 3, listo
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (2, 6, 3, '2026-04-15 18:00:00', 'en local', 'entregado', 150.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(9, 8, 1, 65.00), (9, 12, 2, 25.00), (9, 16, 1, 35.00);

-- Pedido 10 - Los Mochis, cajero Fabiola, cliente 6, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (3, 9, 6, '2026-04-16 13:00:00', 'en local', 'entregado', 220.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(10, 2, 3, 40.00), (10, 10, 2, 22.00), (10, 14, 1, 45.00), (10, 17, 1, 30.00);

-- Pedido 11 - Guasave, cajero Héctor, público, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (4, 12, NULL, '2026-04-17 14:30:00', 'para llevar', 'entregado', 130.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(11, 3, 2, 38.00), (11, 11, 1, 20.00), (11, 15, 1, 40.00);

-- Pedido 12 - Culiacán, cajero Karla, cliente 9, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (1, 2, 9, '2026-04-20 12:00:00', 'en local', 'entregado', 178.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(12, 1, 2, 45.00), (12, 13, 2, 30.00), (12, 19, 1, 20.00), (12, 18, 1, 10.00);

-- Pedido 13 - Mazatlán, cajero Jesús, cliente 10, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (2, 6, 10, '2026-04-22 19:30:00', 'a domicilio', 'entregado', 195.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(13, 4, 2, 55.00), (13, 7, 1, 70.00), (13, 18, 1, 10.00);

-- Pedido 14 - Los Mochis, cajero Fabiola, público, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (3, 9, NULL, '2026-04-25 11:30:00', 'para llevar', 'entregado', 145.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(14, 5, 3, 28.00), (14, 12, 2, 25.00), (14, 16, 1, 35.00);

-- Pedido 15 - Guasave, cajero Héctor, cliente 7, entregado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (4, 12, 7, '2026-04-28 20:00:00', 'en local', 'entregado', 255.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(15, 9, 2, 85.00), (15, 10, 2, 22.00), (15, 14, 1, 45.00);

-- Pedido 16 - Culiacán, Karla, público, entregado (Mayo)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (1, 2, NULL, '2026-05-01 12:00:00', 'en local', 'entregado', 120.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(16, 2, 2, 40.00), (16, 11, 2, 20.00);

-- Pedido 17 - Mazatlán, Jesús, cliente 4, entregado (Mayo)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (2, 6, 4, '2026-05-03 18:00:00', 'para llevar', 'entregado', 210.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(17, 6, 2, 75.00), (17, 13, 2, 30.00);

-- Pedido 18 - Los Mochis, Fabiola, cliente 5, entregado (Mayo)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (3, 9, 5, '2026-05-05 13:00:00', 'en local', 'entregado', 160.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(18, 3, 2, 38.00), (18, 10, 2, 22.00), (18, 17, 1, 30.00);

-- Pedido 19 - Guasave, Héctor, cliente 8, entregado (Mayo)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (4, 12, 8, '2026-05-06 19:00:00', 'a domicilio', 'entregado', 195.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(19, 7, 2, 70.00), (19, 15, 1, 40.00), (19, 18, 1, 10.00);

-- Pedido 20 - Culiacán, Karla, cliente 1, entregado (Mayo)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (1, 2, 1, '2026-05-08 12:30:00', 'en local', 'entregado', 230.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(20, 1, 3, 45.00), (20, 12, 2, 25.00), (20, 14, 1, 45.00);

-- Pedido 21 - Mazatlán, Jesús, público, entregado (Mayo)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (2, 6, NULL, '2026-05-09 14:00:00', 'para llevar', 'entregado', 185.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(21, 4, 2, 55.00), (21, 11, 2, 20.00), (21, 17, 1, 30.00);

-- Pedido 22 - Los Mochis, Fabiola, público, entregado (Mayo)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (3, 9, NULL, '2026-05-10 11:00:00', 'en local', 'entregado', 150.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(22, 5, 2, 28.00), (22, 13, 1, 30.00), (22, 19, 1, 20.00), (22, 18, 2, 10.00);

-- Pedido 23 - Guasave, Héctor, cliente 7, listo (Mayo)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (4, 12, 7, '2026-05-12 20:00:00', 'en local', 'listo', 170.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(23, 8, 1, 65.00), (23, 10, 2, 22.00), (23, 16, 1, 35.00);

-- Pedido 24 - Culiacán, Karla, cliente 2, preparando (Mayo)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (1, 2, 2, '2026-05-14 13:00:00', 'a domicilio', 'preparando', 240.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(24, 9, 2, 85.00), (24, 12, 1, 25.00), (24, 14, 1, 45.00);

-- Pedido 25 - Mazatlán, Jesús, público, pendiente (hoy)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (2, 6, NULL, '2026-05-16 09:00:00', 'en local', 'pendiente', 110.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(25, 2, 2, 40.00), (25, 18, 1, 10.00), (25, 13, 1, 30.00);

-- Pedido 26 - Los Mochis, Fabiola, cliente 6, cancelado
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (3, 9, 6, '2026-05-13 14:00:00', 'para llevar', 'cancelado', 0.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(26, 6, 1, 75.00), (26, 11, 1, 20.00);

-- Pedido 27 - Culiacán, Karla, público, entregado (Mayo)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (1, 2, NULL, '2026-05-15 12:00:00', 'en local', 'entregado', 178.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(27, 1, 2, 45.00), (27, 7, 1, 70.00), (27, 18, 1, 10.00);

-- Pedido 28 - Guasave, Héctor, cliente 8, entregado (Mayo)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (4, 12, 8, '2026-05-15 18:30:00', 'a domicilio', 'entregado', 195.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(28, 4, 2, 55.00), (28, 10, 2, 22.00), (28, 17, 1, 30.00);

-- Pedido 29 - Mazatlán, Jesús, cliente 10, entregado (Mayo)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (2, 6, 10, '2026-05-15 19:00:00', 'para llevar', 'entregado', 145.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(29, 3, 2, 38.00), (29, 11, 1, 20.00), (29, 16, 1, 35.00);

-- Pedido 30 - Los Mochis, Fabiola, público, pendiente (hoy)
INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, fecha_hora, tipo_pedido, estatus, total)
VALUES (3, 9, NULL, '2026-05-16 10:30:00', 'en local', 'pendiente', 125.00);
INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(30, 5, 3, 28.00), (30, 12, 1, 25.00), (30, 13, 1, 30.00);
GO

IF OBJECT_ID('sp_NuevoPedido', 'P') IS NOT NULL DROP PROCEDURE sp_NuevoPedido;
GO

CREATE PROCEDURE sp_NuevoPedido
    @sucursal_id  INT,
    @empleado_id  INT,
    @cliente_id   INT = NULL,
    @tipo_pedido  VARCHAR(15),
    @pedido_id    INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

                IF NOT EXISTS (SELECT 1 FROM Sucursales WHERE sucursal_id = @sucursal_id AND estatus = 'activa')
            THROW 50001, 'La sucursal no existe o está cerrada.', 1;

        
        IF NOT EXISTS (
            SELECT 1 FROM Empleados
            WHERE empleado_id = @empleado_id
              AND estatus = 'activo'
              AND sucursal_id = @sucursal_id
        )
            THROW 50002, 'El empleado no existe, está inactivo o no pertenece a esta sucursal.', 1;

               IF @tipo_pedido NOT IN ('en local', 'para llevar', 'a domicilio')
            THROW 50003, 'Tipo de pedido inválido.', 1;

                IF @cliente_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Clientes WHERE cliente_id = @cliente_id)
            THROW 50004, 'El cliente no existe.', 1;

        
        INSERT INTO Pedidos (sucursal_id, empleado_id, cliente_id, tipo_pedido, estatus, total)
        VALUES (@sucursal_id, @empleado_id, @cliente_id, @tipo_pedido, 'pendiente', 0);

        SET @pedido_id = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

IF OBJECT_ID('sp_AgregarProductoAlPedido', 'P') IS NOT NULL DROP PROCEDURE sp_AgregarProductoAlPedido;
GO

CREATE PROCEDURE sp_AgregarProductoAlPedido
    @pedido_id   INT,
    @producto_id INT,
    @cantidad    INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

                IF NOT EXISTS (SELECT 1 FROM Pedidos WHERE pedido_id = @pedido_id AND estatus = 'pendiente')
            THROW 50010, 'El pedido no existe o no está en estatus pendiente.', 1;

                DECLARE @precio_actual DECIMAL(10,2);
        SELECT @precio_actual = precio
        FROM Productos
        WHERE producto_id = @producto_id AND estatus = 'disponible';

        IF @precio_actual IS NULL
            THROW 50011, 'El producto no existe o no está disponible.', 1;

               IF @cantidad <= 0
            THROW 50012, 'La cantidad debe ser mayor a cero.', 1;

        IF EXISTS (SELECT 1 FROM DetallePedido WHERE pedido_id = @pedido_id AND producto_id = @producto_id)
        BEGIN
            UPDATE DetallePedido
            SET cantidad = cantidad + @cantidad
            WHERE pedido_id = @pedido_id AND producto_id = @producto_id;
        END
        ELSE
        BEGIN
            
            INSERT INTO DetallePedido (pedido_id, producto_id, cantidad, precio_unitario)
            VALUES (@pedido_id, @producto_id, @cantidad, @precio_actual);
        END

        UPDATE Pedidos
        SET total = (SELECT SUM(subtotal) FROM DetallePedido WHERE pedido_id = @pedido_id)
        WHERE pedido_id = @pedido_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


IF OBJECT_ID('sp_AplicarPromocion', 'P') IS NOT NULL DROP PROCEDURE sp_AplicarPromocion;
GO

CREATE PROCEDURE sp_AplicarPromocion
    @pedido_id    INT,
    @promocion_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM Pedidos WHERE pedido_id = @pedido_id AND estatus = 'pendiente')
            THROW 50020, 'El pedido no existe o no está en estatus pendiente.', 1;

        
        DECLARE @descuento DECIMAL(5,2);
        SELECT @descuento = descuento_pct
        FROM Promociones
        WHERE promocion_id = @promocion_id
          AND CAST(GETDATE() AS DATE) BETWEEN fecha_inicio AND fecha_fin;

        IF @descuento IS NULL
            THROW 50021, 'La promoción no existe o no está vigente.', 1;

        
        DECLARE @subtotal_con_promo DECIMAL(10,2);
        DECLARE @subtotal_sin_promo DECIMAL(10,2);

        SELECT
            @subtotal_con_promo = SUM(
                CASE WHEN pp.producto_id IS NOT NULL
                     THEN dp.subtotal * (1 - @descuento / 100.0)
                     ELSE dp.subtotal
                END
            ),
            @subtotal_sin_promo = SUM(dp.subtotal)
        FROM DetallePedido dp
        LEFT JOIN PromocionProductos pp
            ON dp.producto_id = pp.producto_id
           AND pp.promocion_id = @promocion_id
        WHERE dp.pedido_id = @pedido_id;

        
        UPDATE Pedidos
        SET total = @subtotal_con_promo
        WHERE pedido_id = @pedido_id;

        COMMIT TRANSACTION;

                SELECT
            @subtotal_sin_promo            AS total_sin_descuento,
            @subtotal_con_promo            AS total_con_descuento,
            @subtotal_sin_promo - @subtotal_con_promo AS ahorro;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


IF OBJECT_ID('sp_ConfirmarPedido', 'P') IS NOT NULL DROP PROCEDURE sp_ConfirmarPedido;
GO

CREATE PROCEDURE sp_ConfirmarPedido
    @pedido_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        
        IF NOT EXISTS (SELECT 1 FROM Pedidos WHERE pedido_id = @pedido_id AND estatus = 'pendiente')
            THROW 50030, 'El pedido no existe o ya no está en estatus pendiente.', 1;

        
        IF NOT EXISTS (SELECT 1 FROM DetallePedido WHERE pedido_id = @pedido_id)
            THROW 50031, 'No se puede confirmar un pedido sin productos.', 1;

        UPDATE Pedidos SET estatus = 'preparando' WHERE pedido_id = @pedido_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


IF OBJECT_ID('sp_CambiarEstatusPedido', 'P') IS NOT NULL DROP PROCEDURE sp_CambiarEstatusPedido;
GO

CREATE PROCEDURE sp_CambiarEstatusPedido
    @pedido_id     INT,
    @nuevo_estatus VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @estatus_actual VARCHAR(15);
        SELECT @estatus_actual = estatus FROM Pedidos WHERE pedido_id = @pedido_id;

        IF @estatus_actual IS NULL
            THROW 50040, 'El pedido no existe.', 1;

        IF @estatus_actual = 'cancelado'
            THROW 50041, 'Un pedido cancelado no puede cambiar de estatus.', 1;

           IF (@estatus_actual = 'pendiente'   AND @nuevo_estatus = 'preparando') OR
           (@estatus_actual = 'preparando'  AND @nuevo_estatus = 'listo')      OR
           (@estatus_actual = 'listo'       AND @nuevo_estatus = 'entregado')
        BEGIN
            UPDATE Pedidos SET estatus = @nuevo_estatus WHERE pedido_id = @pedido_id;
        END
        ELSE
        BEGIN
            THROW 50042, 'Transición de estatus no permitida. El flujo es: pendiente → preparando → listo → entregado.', 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

IF OBJECT_ID('sp_CancelarPedido', 'P') IS NOT NULL DROP PROCEDURE sp_CancelarPedido;
GO

CREATE PROCEDURE sp_CancelarPedido
    @pedido_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @estatus_actual VARCHAR(15);
        SELECT @estatus_actual = estatus FROM Pedidos WHERE pedido_id = @pedido_id;

        IF @estatus_actual IS NULL
            THROW 50050, 'El pedido no existe.', 1;

        IF @estatus_actual NOT IN ('pendiente', 'preparando')
            THROW 50051, 'Solo se pueden cancelar pedidos en estatus pendiente o preparando.', 1;

        UPDATE Pedidos SET estatus = 'cancelado' WHERE pedido_id = @pedido_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

IF OBJECT_ID('sp_CancelarPedidosVencidos', 'P') IS NOT NULL DROP PROCEDURE sp_CancelarPedidosVencidos;
GO

CREATE PROCEDURE sp_CancelarPedidosVencidos
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Pedidos
        SET estatus = 'cancelado'
        WHERE estatus = 'pendiente'
          AND DATEDIFF(HOUR, fecha_hora, GETDATE()) > 24;

        DECLARE @cancelados INT = @@ROWCOUNT;
        COMMIT TRANSACTION;

        SELECT @cancelados AS pedidos_cancelados_automaticamente;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

IF OBJECT_ID('sp_ReporteVentasSucursal', 'P') IS NOT NULL DROP PROCEDURE sp_ReporteVentasSucursal;
GO

CREATE PROCEDURE sp_ReporteVentasSucursal
    @fecha_inicio DATE = NULL,
    @fecha_fin    DATE = NULL,
    @sucursal_id  INT  = NULL     
AS
BEGIN
    SET NOCOUNT ON;

    
    IF @fecha_inicio IS NULL SET @fecha_inicio = DATEADD(MONTH, -1, CAST(GETDATE() AS DATE));
    IF @fecha_fin    IS NULL SET @fecha_fin    = CAST(GETDATE() AS DATE);

       SELECT
        s.nombre                        AS sucursal,
        s.ciudad,
        COUNT(p.pedido_id)              AS total_pedidos,
        SUM(p.total)                    AS total_ventas,
        ROUND(AVG(p.total), 2)          AS ticket_promedio
    FROM Pedidos p
    INNER JOIN Sucursales s ON p.sucursal_id = s.sucursal_id
    WHERE p.estatus = 'entregado'
      AND CAST(p.fecha_hora AS DATE) BETWEEN @fecha_inicio AND @fecha_fin
      AND (@sucursal_id IS NULL OR p.sucursal_id = @sucursal_id)
    GROUP BY s.sucursal_id, s.nombre, s.ciudad
    ORDER BY total_ventas DESC;
END;
GO


IF OBJECT_ID('sp_ReporteProductosMasVendidos', 'P') IS NOT NULL DROP PROCEDURE sp_ReporteProductosMasVendidos;
GO

CREATE PROCEDURE sp_ReporteProductosMasVendidos
    @fecha_inicio DATE = NULL,
    @fecha_fin    DATE = NULL,
    @sucursal_id  INT  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @fecha_inicio IS NULL SET @fecha_inicio = DATEADD(MONTH, -1, CAST(GETDATE() AS DATE));
    IF @fecha_fin    IS NULL SET @fecha_fin    = CAST(GETDATE() AS DATE);

    SELECT TOP 10
        pr.nombre                       AS producto,
        c.nombre                        AS categoria,
        SUM(dp.cantidad)                AS unidades_vendidas,
        SUM(dp.subtotal)                AS total_generado
    FROM DetallePedido dp
    INNER JOIN Pedidos p   ON dp.pedido_id   = p.pedido_id
    INNER JOIN Productos pr ON dp.producto_id = pr.producto_id
    INNER JOIN Categorias c ON pr.categoria_id = c.categoria_id
    WHERE p.estatus = 'entregado'
      AND CAST(p.fecha_hora AS DATE) BETWEEN @fecha_inicio AND @fecha_fin
      AND (@sucursal_id IS NULL OR p.sucursal_id = @sucursal_id)
    GROUP BY pr.producto_id, pr.nombre, c.nombre
    ORDER BY unidades_vendidas DESC;
END;
GO


IF OBJECT_ID('sp_ReporteRendimientoEmpleados', 'P') IS NOT NULL DROP PROCEDURE sp_ReporteRendimientoEmpleados;
GO

CREATE PROCEDURE sp_ReporteRendimientoEmpleados
    @fecha_inicio DATE = NULL,
    @fecha_fin    DATE = NULL,
    @sucursal_id  INT  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @fecha_inicio IS NULL SET @fecha_inicio = DATEADD(MONTH, -1, CAST(GETDATE() AS DATE));
    IF @fecha_fin    IS NULL SET @fecha_fin    = CAST(GETDATE() AS DATE);

    SELECT
        e.nombre_completo               AS empleado,
        e.puesto,
        s.nombre                        AS sucursal,
        COUNT(p.pedido_id)              AS pedidos_atendidos,
        SUM(p.total)                    AS total_vendido,
        ROUND(AVG(p.total), 2)          AS ticket_promedio
    FROM Pedidos p
    INNER JOIN Empleados e   ON p.empleado_id  = e.empleado_id
    INNER JOIN Sucursales s  ON p.sucursal_id  = s.sucursal_id
    WHERE p.estatus = 'entregado'
      AND CAST(p.fecha_hora AS DATE) BETWEEN @fecha_inicio AND @fecha_fin
      AND (@sucursal_id IS NULL OR p.sucursal_id = @sucursal_id)
    GROUP BY e.empleado_id, e.nombre_completo, e.puesto, s.nombre
    HAVING COUNT(p.pedido_id) > 5
    ORDER BY total_vendido DESC;
END;
GO

IF OBJECT_ID('sp_ReporteComparativoMensual', 'P') IS NOT NULL DROP PROCEDURE sp_ReporteComparativoMensual;
GO

CREATE PROCEDURE sp_ReporteComparativoMensual
    @anio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @anio IS NULL SET @anio = YEAR(GETDATE());

    SELECT
        MONTH(p.fecha_hora)             AS mes,
        DATENAME(MONTH, p.fecha_hora)   AS nombre_mes,
        s.nombre                        AS sucursal,
        COUNT(p.pedido_id)              AS total_pedidos,
        SUM(p.total)                    AS total_ventas
    FROM Pedidos p
    INNER JOIN Sucursales s ON p.sucursal_id = s.sucursal_id
    WHERE p.estatus = 'entregado'
      AND YEAR(p.fecha_hora) = @anio
    GROUP BY MONTH(p.fecha_hora), DATENAME(MONTH, p.fecha_hora), s.sucursal_id, s.nombre
    ORDER BY mes, s.nombre;
END;
GO

IF OBJECT_ID('sp_ReporteProductosSinMovimiento', 'P') IS NOT NULL DROP PROCEDURE sp_ReporteProductosSinMovimiento;
GO

CREATE PROCEDURE sp_ReporteProductosSinMovimiento
    @fecha_inicio DATE = NULL,
    @fecha_fin    DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @fecha_inicio IS NULL SET @fecha_inicio = DATEADD(MONTH, -1, CAST(GETDATE() AS DATE));
    IF @fecha_fin    IS NULL SET @fecha_fin    = CAST(GETDATE() AS DATE);

    SELECT
        pr.nombre       AS producto,
        c.nombre        AS categoria,
        pr.precio       AS precio_venta,
        pr.estatus
    FROM Productos pr
    INNER JOIN Categorias c ON pr.categoria_id = c.categoria_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM DetallePedido dp
        INNER JOIN Pedidos p ON dp.pedido_id = p.pedido_id
        WHERE dp.producto_id = pr.producto_id
          AND p.estatus = 'entregado'
          AND CAST(p.fecha_hora AS DATE) BETWEEN @fecha_inicio AND @fecha_fin
    )
    ORDER BY c.nombre, pr.nombre;
END;
GO

IF OBJECT_ID('sp_ReporteVentasPorCategoria', 'P') IS NOT NULL DROP PROCEDURE sp_ReporteVentasPorCategoria;
GO

CREATE PROCEDURE sp_ReporteVentasPorCategoria
    @fecha_inicio DATE = NULL,
    @fecha_fin    DATE = NULL,
    @sucursal_id  INT  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @fecha_inicio IS NULL SET @fecha_inicio = DATEADD(MONTH, -1, CAST(GETDATE() AS DATE));
    IF @fecha_fin    IS NULL SET @fecha_fin    = CAST(GETDATE() AS DATE);

    SELECT
        c.nombre                        AS categoria,
        SUM(dp.cantidad)                AS unidades_vendidas,
        SUM(dp.subtotal)                AS total_generado
    FROM DetallePedido dp
    INNER JOIN Pedidos p    ON dp.pedido_id    = p.pedido_id
    INNER JOIN Productos pr ON dp.producto_id  = pr.producto_id
    INNER JOIN Categorias c ON pr.categoria_id = c.categoria_id
    WHERE p.estatus = 'entregado'
      AND CAST(p.fecha_hora AS DATE) BETWEEN @fecha_inicio AND @fecha_fin
      AND (@sucursal_id IS NULL OR p.sucursal_id = @sucursal_id)
    GROUP BY c.categoria_id, c.nombre
    ORDER BY total_generado DESC;
END;
GO


IF OBJECT_ID('v_PedidosCompletos', 'V') IS NOT NULL DROP VIEW v_PedidosCompletos;
GO
CREATE VIEW v_PedidosCompletos AS
SELECT
    p.pedido_id,
    p.fecha_hora,
    s.nombre            AS sucursal,
    s.ciudad,
    e.nombre_completo   AS empleado,
    e.puesto,
    ISNULL(c.nombre, 'Público General') AS cliente,
    p.tipo_pedido,
    p.estatus,
    p.total
FROM Pedidos p
INNER JOIN Sucursales s ON p.sucursal_id = s.sucursal_id
INNER JOIN Empleados e  ON p.empleado_id  = e.empleado_id
LEFT  JOIN Clientes c   ON p.cliente_id   = c.cliente_id;
GO

IF OBJECT_ID('v_DetallePedidosCompleto', 'V') IS NOT NULL DROP VIEW v_DetallePedidosCompleto;
GO
CREATE VIEW v_DetallePedidosCompleto AS
SELECT
    dp.detalle_id,
    dp.pedido_id,
    p.fecha_hora,
    p.estatus           AS estatus_pedido,
    pr.nombre           AS producto,
    cat.nombre          AS categoria,
    dp.cantidad,
    dp.precio_unitario,
    dp.subtotal
FROM DetallePedido dp
INNER JOIN Pedidos p    ON dp.pedido_id    = p.pedido_id
INNER JOIN Productos pr ON dp.producto_id  = pr.producto_id
INNER JOIN Categorias cat ON pr.categoria_id = cat.categoria_id;
GO

IF OBJECT_ID('v_PromocionesVigentes', 'V') IS NOT NULL DROP VIEW v_PromocionesVigentes;
GO
CREATE VIEW v_PromocionesVigentes AS
SELECT
    prom.promocion_id,
    prom.nombre         AS promocion,
    prom.descuento_pct,
    prom.fecha_inicio,
    prom.fecha_fin,
    pr.nombre           AS producto_aplicable,
    pr.precio           AS precio_normal,
    ROUND(pr.precio * (1 - prom.descuento_pct/100.0), 2) AS precio_con_descuento
FROM Promociones prom
INNER JOIN PromocionProductos pp ON prom.promocion_id = pp.promocion_id
INNER JOIN Productos pr          ON pp.producto_id    = pr.producto_id
WHERE CAST(GETDATE() AS DATE) BETWEEN prom.fecha_inicio AND prom.fecha_fin;
GO


PRINT 'TacoSoft - Base de datos creada exitosamente';
PRINT '';
PRINT '=== RESUMEN DE DATOS ===';
SELECT 'Sucursales'       AS tabla, COUNT(*) AS registros FROM Sucursales     UNION ALL
SELECT 'Categorias',              COUNT(*) FROM Categorias                    UNION ALL
SELECT 'Productos',               COUNT(*) FROM Productos                     UNION ALL
SELECT 'Empleados',               COUNT(*) FROM Empleados                     UNION ALL
SELECT 'Clientes',                COUNT(*) FROM Clientes                      UNION ALL
SELECT 'Pedidos',                 COUNT(*) FROM Pedidos                       UNION ALL
SELECT 'DetallePedido',           COUNT(*) FROM DetallePedido                 UNION ALL
SELECT 'Promociones',             COUNT(*) FROM Promociones                   UNION ALL
SELECT 'PromocionProductos',      COUNT(*) FROM PromocionProductos;
GO