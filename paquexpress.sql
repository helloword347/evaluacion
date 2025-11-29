

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";



CREATE TABLE `agente` (
  `id_agente` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `usuario` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


INSERT INTO `agente` (`id_agente`, `nombre`, `usuario`, `password_hash`, `activo`, `fecha_creacion`) VALUES
(1, 'Agente de Prueba', 'test_agent', '$2b$12$R.S/XfI2D.f7D1jP5QzU9eG1eJ0/Y5pQ0/K2xR2z/N.P1xL0/C5K2', 1, '2025-11-29 17:40:02'),
(2, 'luis', 'luis1', '2541a118acb3adc75811a5c53119bd5b29ade2877c0909eeb7d177e96bbfc9d3', 1, '2025-11-29 18:45:07'),
(3, 'carlos', 'carlos1', '49b89fb61621dba29036bfb80d9c779d1c8d45ec891720f4a2b85ca648db0b01', 1, '2025-11-29 18:46:53'),
(4, 'Luis', 'luis24', '2fb7c6895096e2a7ca7f3eaad8ca391231ed02d47f471779e6c0131a104b6b49', 1, '2025-11-29 19:45:24');



CREATE TABLE `direccion` (
  `id_direccion` int(11) NOT NULL,
  `calle_numero` varchar(100) NOT NULL,
  `colonia` varchar(100) NOT NULL,
  `ciudad` varchar(100) NOT NULL,
  `codigo_postal` varchar(10) NOT NULL,
  `latitud_destino` float NOT NULL,
  `longitud_destino` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



INSERT INTO `direccion` (`id_direccion`, `calle_numero`, `colonia`, `ciudad`, `codigo_postal`, `latitud_destino`, `longitud_destino`) VALUES
(1, 'Av. Del Sol 15', 'Colonia Central', 'Queretaro', '10001', 20.6505, -100.405),
(3, 'playa', 'Colonia Central', 'Queretaro', '10001', 19.132, -100.421),
(4, 'av. del sol', 'Colonia Central', 'Michoacán ', '10001', 20.6505, -100.405),
(5, 'carmen', 'Colonia Central', 'Ciudad Ejemplo', '10001', 19.476, -100.4),
(6, 'playa costa', 'Colonia Central', 'Ciudad Ejemplo', '10001', 19.4234, -100.532);


CREATE TABLE `paquete` (
  `id_paquete` varchar(50) NOT NULL,
  `id_direccion_fk` int(11) NOT NULL,
  `id_agente_asignado_fk` int(11) NOT NULL,
  `estado` enum('Asignado','En Ruta','Entregado','Cancelado') NOT NULL,
  `fecha_asignacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


INSERT INTO `paquete` (`id_paquete`, `id_direccion_fk`, `id_agente_asignado_fk`, `estado`, `fecha_asignacion`) VALUES
('1', 4, 3, 'Entregado', '2025-11-30 01:05:53'),
('2', 3, 3, 'Entregado', '2025-11-30 00:54:18'),
('44', 6, 4, 'Entregado', '2025-11-30 01:46:57'),
('5', 5, 2, 'Asignado', '2025-11-30 01:35:44'),
('PAQ-001', 1, 1, 'Asignado', '2025-11-29 17:40:02');


CREATE TABLE `registroentrega` (
  `id_entrega` int(11) NOT NULL,
  `id_paquete_fk` varchar(50) NOT NULL,
  `id_agente_fk` int(11) NOT NULL,
  `ruta_foto` varchar(255) NOT NULL,
  `latitud_gps` float NOT NULL,
  `longitud_gps` float NOT NULL,
  `fecha_entrega` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


INSERT INTO `registroentrega` (`id_entrega`, `id_paquete_fk`, `id_agente_fk`, `ruta_foto`, `latitud_gps`, `longitud_gps`, `fecha_entrega`) VALUES
(1, '44', 4, 'uploads/44_20251129134747_xanadu.jpg', 20.5642, -100.394, '2025-11-30 01:47:47'),
(2, '1', 3, 'uploads/1_20251129134900_xanadu.jpg', 20.5642, -100.394, '2025-11-30 01:49:00'),
(3, '2', 3, 'uploads/2_20251129134926_gato.jpg', 20.5642, -100.394, '2025-11-30 01:49:26');



CREATE TABLE `sesionagente` (
  `id_sesion` int(11) NOT NULL,
  `id_agente_fk` int(11) NOT NULL,
  `token_sesion` varchar(255) NOT NULL,
  `inicio_sesion` timestamp NOT NULL DEFAULT current_timestamp(),
  `fin_sesion` timestamp NULL DEFAULT NULL,
  `dispositivo_info` varchar(150) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


ALTER TABLE `agente`
  ADD PRIMARY KEY (`id_agente`),
  ADD UNIQUE KEY `usuario` (`usuario`);

ALTER TABLE `direccion`
  ADD PRIMARY KEY (`id_direccion`);


ALTER TABLE `paquete`
  ADD PRIMARY KEY (`id_paquete`),
  ADD KEY `id_direccion_fk` (`id_direccion_fk`),
  ADD KEY `id_agente_asignado_fk` (`id_agente_asignado_fk`);


ALTER TABLE `registroentrega`
  ADD PRIMARY KEY (`id_entrega`),
  ADD UNIQUE KEY `id_paquete_fk` (`id_paquete_fk`),
  ADD KEY `id_agente_fk` (`id_agente_fk`);


ALTER TABLE `sesionagente`
  ADD PRIMARY KEY (`id_sesion`),
  ADD UNIQUE KEY `token_sesion` (`token_sesion`),
  ADD KEY `id_agente_fk` (`id_agente_fk`);


ALTER TABLE `agente`
  MODIFY `id_agente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;


ALTER TABLE `direccion`
  MODIFY `id_direccion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

ALTER TABLE `registroentrega`
  MODIFY `id_entrega` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;


ALTER TABLE `sesionagente`
  MODIFY `id_sesion` int(11) NOT NULL AUTO_INCREMENT;


ALTER TABLE `paquete`
  ADD CONSTRAINT `paquete_ibfk_1` FOREIGN KEY (`id_direccion_fk`) REFERENCES `direccion` (`id_direccion`),
  ADD CONSTRAINT `paquete_ibfk_2` FOREIGN KEY (`id_agente_asignado_fk`) REFERENCES `agente` (`id_agente`);


ALTER TABLE `registroentrega`
  ADD CONSTRAINT `registroentrega_ibfk_1` FOREIGN KEY (`id_paquete_fk`) REFERENCES `paquete` (`id_paquete`),
  ADD CONSTRAINT `registroentrega_ibfk_2` FOREIGN KEY (`id_agente_fk`) REFERENCES `agente` (`id_agente`);

ALTER TABLE `sesionagente`
  ADD CONSTRAINT `sesionagente_ibfk_1` FOREIGN KEY (`id_agente_fk`) REFERENCES `agente` (`id_agente`);
COMMIT;

