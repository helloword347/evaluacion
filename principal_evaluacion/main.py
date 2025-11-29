from datetime import datetime
from typing import Optional, List


from fastapi import FastAPI, UploadFile, Form, File, HTTPException, Depends
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, Integer, String, TIMESTAMP, Float, Boolean, ForeignKey, Enum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from pydantic import BaseModel, Field


import shutil
import os
import hashlib



app = FastAPI()


if not os.path.exists("uploads"):
    os.makedirs("uploads") 

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DATABASE_URL = "mysql+pymysql://root:@127.0.0.1/paquexpress"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_password_hash(password: str) -> str:
    """Función temporal de hashing"""
    validated_password = password[:50]
    salt = "paquexpress_salt_2024"
    return hashlib.sha256(f"{validated_password}{salt}".encode()).hexdigest()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verificar contraseña con nuestro método temporal"""
    validated_password = plain_password[:50]
    salt = "paquexpress_salt_2024"
    test_hash = hashlib.sha256(f"{validated_password}{salt}".encode()).hexdigest()
    return test_hash == hashed_password


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class Agente(Base):
    __tablename__ = "agente" 
    id_agente = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    usuario = Column(String(50), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    activo = Column(Boolean, default=True)

class Direccion(Base):
    __tablename__ = "direccion"
    id_direccion = Column(Integer, primary_key=True, index=True)
    calle_numero = Column(String(100), nullable=False)
    colonia = Column(String(100), nullable=False)
    ciudad = Column(String(100), nullable=False)
    codigo_postal = Column(String(10), nullable=False)
    latitud_destino = Column(Float, nullable=False)
    longitud_destino = Column(Float, nullable=False)

class Paquete(Base):
    __tablename__ = "paquete"
    id_paquete = Column(String(50), primary_key=True, index=True)
    id_direccion_fk = Column(Integer, ForeignKey("direccion.id_direccion"), nullable=False)
    id_agente_asignado_fk = Column(Integer, ForeignKey("agente.id_agente"), nullable=False)
    estado = Column(Enum("Asignado", "En Ruta", "Entregado", "Cancelado"), nullable=False, default="Asignado")
    fecha_asignacion = Column(TIMESTAMP, default=datetime.utcnow)
    
    direccion = relationship("Direccion")
    agente = relationship("Agente")

class RegistroEntrega(Base):
    __tablename__ = "registroentrega"
    id_entrega = Column(Integer, primary_key=True, index=True)
    id_paquete_fk = Column(String(50), ForeignKey("paquete.id_paquete"), nullable=False, unique=True)
    id_agente_fk = Column(Integer, ForeignKey("agente.id_agente"), nullable=False)
    ruta_foto = Column(String(255), nullable=False)
    latitud_gps = Column(Float, nullable=False)
    longitud_gps = Column(Float, nullable=False)
    fecha_entrega = Column(TIMESTAMP, default=datetime.utcnow)
    
    paquete = relationship("Paquete")

class SesionAgente(Base):
    __tablename__ = "sesionagente"
    id_sesion = Column(Integer, primary_key=True, index=True)
    id_agente_fk = Column(Integer, ForeignKey("agente.id_agente"), nullable=False)
    token_sesion = Column(String(255), nullable=False, unique=True)
    inicio_sesion = Column(TIMESTAMP, default=datetime.utcnow)
    fin_sesion = Column(TIMESTAMP, nullable=True)


class DireccionSchema(BaseModel):
    id_direccion: int
    calle_numero: str
    colonia: str
    ciudad: str
    latitud_destino: float
    longitud_destino: float
    class Config: from_attributes = True

class AgenteSchema(BaseModel):
    id_agente: int
    nombre: str
    usuario: str
    class Config: from_attributes = True
    
class AgenteLogin(BaseModel):
    usuario: str
    password: str

class PaqueteAsignadoSchema(BaseModel):
    id_paquete: str
    id_agente_asignado_fk: int
    estado: str
    direccion: DireccionSchema 
    class Config: from_attributes = True

class EntregaCreateSchema(BaseModel):
    id_paquete_fk: str
    id_agente_fk: int
    ruta_foto: str
    latitud_gps: float
    longitud_gps: float
    fecha_entrega: datetime
    class Config: from_attributes = True


@app.on_event("startup")
async def startup_event():
    try:
        Base.metadata.create_all(bind=engine)
        print("✅ Conexión a BD exitosa")
        
        db = SessionLocal()
        try:
            agente_test = db.query(Agente).filter(Agente.usuario == "test_agent").first()
            if not agente_test:
                hashed_password = get_password_hash("password123")
                nuevo_agente = Agente(
                    nombre="Agente de Prueba", 
                    usuario="test_agent", 
                    password_hash=hashed_password
                )
                db.add(nuevo_agente)
                db.commit()
                print("✅ Agente de prueba creado: test_agent / password123")
            else:
                print("✅ Agente de prueba ya existe")
        finally:
            db.close()
            
    except Exception as e:
        print(f"❌ Error conectando a BD: {e}")

 
@app.post("/agentes/", response_model=AgenteSchema)
def create_agente(
    usuario: str = Form(...), 
    nombre: str = Form(...), 
    password: str = Form(...),
    db: SessionLocal = Depends(get_db)
):
    try: 
        print(f"📝 Creando agente: {usuario}")
        
        if not usuario or not nombre or not password:
            raise HTTPException(status_code=400, detail="Todos los campos son requeridos")
        
        validated_password = password[:50]
        
        db_agente = db.query(Agente).filter(Agente.usuario == usuario).first()
        if db_agente:
            raise HTTPException(status_code=400, detail="El usuario ya existe")
            
        hashed_password = get_password_hash(validated_password) 
        
        nuevo_agente = Agente(nombre=nombre, usuario=usuario, password_hash=hashed_password)
        db.add(nuevo_agente)
        db.commit()
        db.refresh(nuevo_agente)
        
        print(f"✅ Agente creado exitosamente: {usuario}")
        return nuevo_agente
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"💥 Error creando agente: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fatal: {str(e)}")


@app.post("/login/")
def login_for_access_token(agente: AgenteLogin, db: SessionLocal = Depends(get_db)):
    try:
        print(f"🔐 Intento de login para usuario: {agente.usuario}")
        
        if not agente.usuario or not agente.password:
            raise HTTPException(status_code=400, detail="Usuario y contraseña son requeridos")
        
        db_agente = db.query(Agente).filter(Agente.usuario == agente.usuario).first()
        
        if not db_agente:
            print("❌ Usuario no encontrado")
            raise HTTPException(status_code=401, detail="Usuario o contraseña incorrectos")
        
        validated_password = agente.password[:50]
        
        if not verify_password(validated_password, db_agente.password_hash):
            print("❌ Contraseña incorrecta")
            raise HTTPException(status_code=401, detail="Usuario o contraseña incorrectos")

        print("✅ Login exitoso")
        return {
            "msg": "Inicio de sesión exitoso", 
            "id_agente": db_agente.id_agente, 
            "nombre": db_agente.nombre
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"💥 Error en login: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fatal en login: {str(e)}")


@app.post("/paquetes/", response_model=PaqueteAsignadoSchema)
def create_paquete(
    id_paquete: str = Form(...), 
    id_agente_asignado_fk: int = Form(...), 
    calle: str = Form(...), 
    lat: float = Form(...), 
    lon: float = Form(...), 
    db: SessionLocal = Depends(get_db)
):
    try:
        print(f"📦 Creando paquete: {id_paquete}")
        
        # Verificar que el agente existe
        agente = db.query(Agente).filter(Agente.id_agente == id_agente_asignado_fk).first()
        if not agente:
            raise HTTPException(status_code=404, detail="Agente no encontrado")
        
        # Crea la dirección
        nueva_direccion = Direccion(
            calle_numero=calle, 
            colonia="Colonia Central", 
            ciudad="Ciudad Ejemplo", 
            codigo_postal="10001", 
            latitud_destino=lat, 
            longitud_destino=lon
        )
        db.add(nueva_direccion)
        db.flush() 

        # Crea el paquete
        nuevo_paquete = Paquete(
            id_paquete=id_paquete,
            id_direccion_fk=nueva_direccion.id_direccion,
            id_agente_asignado_fk=id_agente_asignado_fk,
            estado="Asignado"
        )
        db.add(nuevo_paquete)
        db.commit()
        db.refresh(nuevo_paquete)
        
        
        nuevo_paquete.direccion = nueva_direccion
        
        print(f"✅ Paquete creado exitosamente: {id_paquete}")
        return nuevo_paquete
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"💥 Error creando paquete: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fatal: {str(e)}")

## LISTAR PAQUETES ASIGNADOS
@app.get("/paquetes/asignados/{id_agente}", response_model=List[PaqueteAsignadoSchema])
def listar_paquetes(id_agente: int, db: SessionLocal = Depends(get_db)):
    try:
        print(f"📋 Listando paquetes para agente: {id_agente}")
        
        paquetes = db.query(Paquete).filter(
            Paquete.id_agente_asignado_fk == id_agente,
            Paquete.estado.in_(["Asignado", "En Ruta"])
        ).all()
        
      
        for p in paquetes:
            p.direccion = db.query(Direccion).filter(Direccion.id_direccion == p.id_direccion_fk).first()
        
        print(f"✅ Encontrados {len(paquetes)} paquetes")
        return paquetes
        
    except Exception as e:
        print(f"💥 Error listando paquetes: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fatal: {str(e)}")

## REGISTRAR ENTREGA
@app.post("/entregas/")
async def registrar_entrega(
    id_paquete_fk: str = Form(...),
    id_agente_fk: int = Form(...),
    latitud_gps: float = Form(...),
    longitud_gps: float = Form(...),
    file: UploadFile = File(...),
    db: SessionLocal = Depends(get_db)
):
    try:
        print(f"📮 Registrando entrega para paquete: {id_paquete_fk}")
        
        paquete = db.query(Paquete).filter(
            Paquete.id_paquete == id_paquete_fk,
            Paquete.id_agente_asignado_fk == id_agente_fk,
            Paquete.estado.in_(["Asignado", "En Ruta"])
        ).first()

        if not paquete:
            raise HTTPException(status_code=404, detail="Paquete no encontrado o no asignado a este agente.")
            
        # Guardar archivo
        nombre_archivo = f"{id_paquete_fk}_{datetime.now().strftime('%Y%m%d%H%M%S')}_{file.filename}"
        ruta = f"uploads/{nombre_archivo}"
        
        with open(ruta, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

       
        nueva_entrega = RegistroEntrega(
            id_paquete_fk=id_paquete_fk,
            id_agente_fk=id_agente_fk,
            ruta_foto=ruta,
            latitud_gps=latitud_gps,
            longitud_gps=longitud_gps
        )
        db.add(nueva_entrega)
        
       
        paquete.estado = "Entregado"
        db.add(paquete)
        
        db.commit()
        db.refresh(nueva_entrega)

        print(f"✅ Entrega registrada exitosamente: {id_paquete_fk}")
        return {
            "msg": f"Entrega del paquete {id_paquete_fk} registrada correctamente.",
            "entrega": EntregaCreateSchema.from_orm(nueva_entrega),
        }
    except HTTPException:
        raise
    except Exception as e:
        if 'ruta' in locals() and os.path.exists(ruta):
             os.remove(ruta)
        print(f"💥 Error registrando entrega: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error interno al guardar la entrega: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)