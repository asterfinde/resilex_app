# Estrategia de Branching - Trunk Based Development

## Estructura de Ramas

### `main`
- **Propósito**: Rama de producción estable
- **Protección**: Solo acepta merges desde ramas de features después de testing
- **Deploy**: Representa el código en producción o listo para producción

### `feature/mvp-ocr-flow`
- **Propósito**: Rama de desarrollo activo para el flujo OCR del MVP
- **Uso**: Desarrollo del flujo completo de procesamiento de tickets
- **Integración**: Se mergea a `main` cuando esté completo y probado

## Workflow de Desarrollo

1. **Desarrollo diario**: Trabajar directamente en `feature/mvp-ocr-flow`
2. **Commits frecuentes**: Hacer commits pequeños y frecuentes
3. **Testing**: Probar localmente antes de cada commit
4. **Merge a main**: Solo cuando el código está estable y probado

## Comandos Útiles

```bash
# Cambiar a la rama de feature para trabajar
git checkout feature/mvp-ocr-flow

# Hacer commits frecuentes
git add .
git commit -m "feat: descripción del cambio"

# Cuando esté listo para producción
git checkout main
git merge feature/mvp-ocr-flow --no-ff -m "release: versión X.Y.Z"
git tag vX.Y.Z

# Volver a la rama de feature
git checkout feature/mvp-ocr-flow
```

## Estado Actual

- ✅ `main`: MVP completo con flujo OCR implementado
- ✅ `feature/mvp-ocr-flow`: Rama activa para desarrollo del flujo OCR
- ❌ Ramas antiguas eliminadas (ya mergeadas)

## Historial de Merges

- **2025-12-05**: Merge de `feature/ocr-csv-export` → `main`
  - Implementación completa del flujo OCR
  - Pantallas de selección y procesamiento
  - HomeScreen con agrupación por mes
  - Modelo ReceiptRecord con ID alfanumérico
