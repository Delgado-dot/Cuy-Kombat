## Resumen para Telegram

Al FINAL de cada respuesta, agrega exactamente este bloque:

---TELEGRAM_SUMMARY---

Resumen:
- [máximo 3 puntos sobre lo que realmente se hizo]

Archivos:
- [archivos realmente modificados]
- Si no se modificaron archivos: Ninguno

Commit:
- [mensaje del commit si existe]
- Hash: [hash corto si existe]
- Si no hubo commit: Ninguno

Pendiente:
- [pendientes reales]
- Si no hay pendientes: Ninguno

Estado:
- [Completada, Completada con pendientes o No completada]

---END_TELEGRAM_SUMMARY---

### Reglas del resumen

- Máximo 3 puntos en "Resumen".
- Sé breve y específico.
- Describe solamente cambios realmente realizados.
- No repitas el prompt del usuario.
- No inventes cambios.
- Los archivos deben ser los que realmente fueron creados, modificados o eliminados durante la tarea.
- Si no se modificaron archivos, escribir "Ninguno".
- Si se realizó un commit, indicar su mensaje y hash corto.
- Si no se realizó un commit, escribir "Ninguno".
- Indicar únicamente pendientes reales.
- Si todo quedó terminado, escribir "Ninguno" en Pendiente.
- El Estado debe reflejar el resultado real de la tarea.
- El bloque debe aparecer siempre al FINAL de la respuesta.
- No colocar explicaciones después de `---END_TELEGRAM_SUMMARY---`.