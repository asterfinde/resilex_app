# Estrategia de Branching - Trunk Based Development

## Estructura de Ramas

### `main`
- **Propósito**: Rama de producción estable
- **Protección**: Solo acepta merges desde `develop` después de testing
- **Deploy**: Representa el código en producción o listo para producción

### `develop`
- **Propósito**: Rama de desarrollo activo
- **Uso**: Todo el trabajo de desarrollo se realiza aquí
- **Integración**: Se mergea a `main` cuando un conjunto de features está completo y probado

## Workflow de Desarrollo

1. **Desarrollo diario**: Trabajar directamente en `develop`
2. **Commits frecuentes**: Hacer commits pequeños y frecuentes
3. **Testing**: Probar localmente antes de cada commit
4. **Merge a main**: Solo cuando el código está estable y probado

## Comandos Útiles

```bash
# Cambiar a develop para trabajar
git checkout develop

# Hacer commits frecuentes
git add .
git commit -m "feat: descripción del cambio"

# Cuando esté listo para producción
git checkout main
git merge develop --no-ff -m "release: versión X.Y.Z"
git tag vX.Y.Z

# Volver a develop
git checkout develop
```

## Estado Actual

- ✅ `main`: MVP completo con flujo OCR implementado
- ✅ `develop`: Rama activa para desarrollo futuro
- ❌ Ramas de features eliminadas (ya mergeadas)

## Historial de Merges

- **2025-12-05**: Merge de `feature/ocr-csv-export` → `main`
  - Implementación completa del flujo OCR
  - Pantallas de selección y procesamiento
  - HomeScreen con agrupación por mes
  - Modelo ReceiptRecord con ID alfanumérico
