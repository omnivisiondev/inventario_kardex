-- -----------------------------------------------------
-- Base de datos: inventario_kardex
-- Diseño: Sistema de Kardex para telecomunicaciones
-- Versión: 1.0 (Diseño inicial del sistema)
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS inventario_kardex;
USE inventario_kardex;

-- -----------------------------------------------------
-- Tabla: categoria
-- -----------------------------------------------------
CREATE TABLE categoria (
    id_categoria INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL,
    descripcion_categoria VARCHAR(150) NOT NULL
);

-- -----------------------------------------------------
-- Tabla: marca
-- -----------------------------------------------------
CREATE TABLE marca (
    id_marca INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre_marca VARCHAR(50) NOT NULL UNIQUE,
    descripcion_marca VARCHAR(150)
);

-- -----------------------------------------------------
-- Tabla: empleado
-- -----------------------------------------------------
CREATE TABLE empleado (
    id_empleado INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    cod_empleado VARCHAR(50) NOT NULL UNIQUE,
    nombre_empleado VARCHAR(35) NOT NULL,
    apellido_empleado VARCHAR(35) NOT NULL,
    contacto_empleado VARCHAR(15),
    email_empleado VARCHAR(50),
    id_empleado_principal INT,
    FOREIGN KEY (id_empleado_principal) REFERENCES empleado(id_empleado)
);

-- -----------------------------------------------------
-- Tabla: producto
-- -----------------------------------------------------
CREATE TABLE producto (
    id_producto INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_categoria INT NOT NULL,
    id_marca INT NOT NULL,
    cod_producto VARCHAR(25) NOT NULL UNIQUE,
    nombre_producto VARCHAR(50) NOT NULL,
    descripcion_producto VARCHAR(250) NOT NULL,
    modelo VARCHAR(150) NULL,
    descripcion_modelo VARCHAR(100) NULL,
    precio_costo DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    precio_venta DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    stock_minimo INT NOT NULL DEFAULT 0,
    stock_actual INT NOT NULL DEFAULT 0,
    FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria),
    FOREIGN KEY (id_marca) REFERENCES marca(id_marca)
);

-- -----------------------------------------------------
-- Tabla: ingreso
-- -----------------------------------------------------
CREATE TABLE ingreso (
    id_ingreso INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    id_empleado INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    fecha_ingreso DATE NOT NULL,
    referencia VARCHAR(150),
    observaciones VARCHAR(150),
    FOREIGN KEY (id_producto) REFERENCES producto(id_producto),
    FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado)
);

-- -----------------------------------------------------
-- Tabla: detalle_ingreso (CORREGIDA - Con MAC address obligatorio para telecom)
-- -----------------------------------------------------
CREATE TABLE detalle_ingreso (
    id_detalle_ingreso INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_ingreso INT NOT NULL,
    id_producto INT NOT NULL,
    mac VARCHAR(30) NOT NULL UNIQUE, -- ✅ MAC address obligatorio y único
    serie VARCHAR(30) NULL, -- Opcional para equipos que también usan serie
    estado_ingreso VARCHAR(25) NOT NULL DEFAULT 'activo',
    FOREIGN KEY (id_ingreso) REFERENCES ingreso(id_ingreso),
    FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

-- -----------------------------------------------------
-- Tabla: inventario
-- -----------------------------------------------------
CREATE TABLE inventario (
    id_inventario INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    id_detalle_ingreso INT NOT NULL, -- ✅ Ahora es NOT NULL (cada unidad tiene MAC)
    estado_actual ENUM('disponible', 'entregado', 'devuelto', 'desechado') NOT NULL DEFAULT 'disponible',
    ubicacion VARCHAR(25) NULL,
    FOREIGN KEY (id_producto) REFERENCES producto(id_producto),
    FOREIGN KEY (id_detalle_ingreso) REFERENCES detalle_ingreso(id_detalle_ingreso)
);

-- -----------------------------------------------------
-- Tabla: solicitud_salida
-- -----------------------------------------------------
CREATE TABLE solicitud_salida (
    id_solicitud_salida INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    cod_salida VARCHAR(20) NOT NULL UNIQUE,
    id_empleado INT NOT NULL,
    estado ENUM('pendiente', 'aprobada', 'rechazada', 'cancelada') NOT NULL DEFAULT 'pendiente',
    fecha_solicitud DATE NOT NULL,
    fecha_aprobacion DATE NULL,
    observaciones VARCHAR(50) NULL,
    FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado)
);

-- -----------------------------------------------------
-- Tabla: solicitud_detalle
-- -----------------------------------------------------
CREATE TABLE solicitud_detalle (
    id_solicitud_detalle INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_solicitud_salida INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad_solicitada INT NOT NULL,
    cantidad_entregada INT NOT NULL DEFAULT 0,
    estado ENUM('pendiente', 'parcial', 'completa', 'cancelada') NOT NULL DEFAULT 'pendiente',
    observaciones VARCHAR(250) NULL,
    FOREIGN KEY (id_solicitud_salida) REFERENCES solicitud_salida(id_solicitud_salida),
    FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

-- -----------------------------------------------------
-- Tabla: orden_entrega
-- -----------------------------------------------------
CREATE TABLE orden_entrega (
    id_orden_entrega INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_empleado INT NOT NULL,
    id_solicitud_salida INT NOT NULL,
    fecha_salida DATE NOT NULL,
    observaciones VARCHAR(250) NULL,
    FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado),
    FOREIGN KEY (id_solicitud_salida) REFERENCES solicitud_salida(id_solicitud_salida)
);

-- -----------------------------------------------------
-- Tabla: entrega_detalle
-- -----------------------------------------------------
CREATE TABLE entrega_detalle (
    id_entrega_detalle INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_orden_entrega INT NOT NULL,
    id_producto INT NOT NULL,
    id_inventario INT NOT NULL, -- ✅ Obligatorio (cada entrega es por MAC)
    cantidad_entregada INT NOT NULL DEFAULT 1, -- ✅ Siempre 1 unidad por MAC
    observaciones VARCHAR(250) NULL,
    FOREIGN KEY (id_orden_entrega) REFERENCES orden_entrega(id_orden_entrega),
    FOREIGN KEY (id_producto) REFERENCES producto(id_producto),
    FOREIGN KEY (id_inventario) REFERENCES inventario(id_inventario)
);

-- -----------------------------------------------------
-- Tabla: log_acciones
-- -----------------------------------------------------
CREATE TABLE log_acciones (
    id_log INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_empleado INT NOT NULL,
    tabla_afectada VARCHAR(50) NOT NULL,
    id_registro_afectado INT NOT NULL,
    tipo_accion ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    descripcion TEXT,
    fecha_accion DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado)
);

-- -----------------------------------------------------
-- Tabla: movimiento_kardex
-- -----------------------------------------------------
CREATE TABLE movimiento_kardex (
    id_movimiento INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    tipo_movimiento ENUM('ingreso', 'salida', 'ajuste') NOT NULL,
    cantidad INT NOT NULL DEFAULT 1, -- ✅ En telecom, 1 unidad = 1 MAC
    precio_unitario DECIMAL(10,2) NOT NULL,
    saldo_anterior INT NOT NULL,
    saldo_actual INT NOT NULL,
    id_referencia INT NOT NULL,
    fecha_movimiento DATETIME DEFAULT CURRENT_TIMESTAMP,
    observaciones VARCHAR(250) NULL,
    FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

-- -----------------------------------------------------
-- Índices para optimización
-- -----------------------------------------------------
CREATE INDEX idx_producto_cod ON producto(cod_producto);
CREATE INDEX idx_ingreso_fecha ON ingreso(fecha_ingreso);
CREATE INDEX idx_solicitud_fecha ON solicitud_salida(fecha_solicitud);
CREATE INDEX idx_kardex_fecha ON movimiento_kardex(fecha_movimiento);
CREATE INDEX idx_log_accion ON log_acciones(tipo_accion);
CREATE INDEX idx_inventario_estado ON inventario(estado_actual);
CREATE UNIQUE INDEX idx_mac ON detalle_ingreso(mac); -- ✅ Índice único para MAC