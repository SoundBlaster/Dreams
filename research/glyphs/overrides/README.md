# Ручные правки контуров

`Gxx.svg` в этой папке заменяет трассировку глифа Gxx. Взять контур в правку:

```sh
.venv/bin/python scripts/glyphs/pipeline.py adopt G06
```

Сохраняй `viewBox`, рисуй внутри `id="glyph"`, после правки запускай `build`. Подробности в [../PIPELINE.md](../PIPELINE.md#ручная-правка-контура).
