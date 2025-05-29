# Скрипты автоматизации


## Media

### mkvmerge.sh

Утилита-обертка над mkvmerge для вставки субтитров и дорожки в mkv-контейнер.

Идея применения такая:
- Размещаем весь сериал **в алфавитном порядке** серий в одном каталоге
- Закидываем первую серию сериала в [MKVToolNix](https://mkvtoolnix.download/) и генерируем команду
- Копируем команду в функцию mkvmerge скрипта и шаблонизурем руками (автоматизировать лень)
- Запускаем с аргументами и ждем, пока скрипт пройдется по всем сериям

Пример шаблонизации команды:
```bash
	$MKVMERGE_BIN \
		--ui-language en_US --priority lower \
		--output "$output_file" \
		--language 0:und --track-name "0:Video" --display-dimensions 0:1920x1080 \
		--color-matrix-coefficients 0:1 --color-transfer-characteristics 0:1 --color-primaries 0:1 \
		--language 1:ja --track-name "1:Original" --default-track-flag 1:no --original-flag 1:yes \
		--language 2:en --track-name "2:English subs" --default-track-flag 2:no --sub-charset 2:UTF-8 \
		'(' "$input_video" ')' \
	- `` | `--language "0:ru" --track-name "0:Studio Band" --default-track-flag 0:yes '(' "$input_audio" '` -' \
	- `` | `--language "0:ru" --track-name "0:Russian subs" --default-track-flag 0:no '(' "$input_subs" '` -' \
		--track-order 0:0,1:0,0:1,2:0,0:2 \
		"${EXTRA_ARGS[@]}"
```

Аргументы:
- `-i` | `--input-dir` `DIR` - каталог с медиа-файлами, default: `.`
- `-o` | `--output-dir` `DIR` - каталог для складывания результатов, default: `$(pwd)_merge`
- `-a` | `--audio-dir` `DIR` - каталог с аудио-дорожками, default: `${input_dir}/RUS Sound`
- `-s` | `--subs-dir` `DIR` - каталог с субтитрами, default: `${input_dir}/SUB`
- `-e` | `--allow-ext` `EXT` - искать медиа с указанным расширением, default: `mkv`
- `-b` | `--mkvmerge-bin` `BIN` - путь до утилиты mkvmerge, default: из приложения MKVToolNix-89.0 на OSX
- `-c` | `--check` - не выполнять mkvmerge, только печатать
- `-f` | `--force` - перезаписывать файлы, если уже есть
- `-y` | `--yes` - не запрашивать подтверждения пользователя
- Позиционные - все добавятся на место EXTRA_ARGS, если вы добавили их в шаблон (логично поместить в конец)

Примеры:
```bash
# Запускаем с check-ом, чтобы убедиться, что все хорошо (и yes, чтобы не подтверждать)
merge-mkv.sh --input-dir /path/to/dir --subs-dir "/path/to/dir/RUS SUB" --check --yes
# Теперь склеиваем
merge-mkv.sh --input-dir /path/to/dir --subs-dir "/path/to/dir/RUS SUB"
# Получаем в `../$(pwd)_merge` обработанные файлы
```


### rename-tvs.sh

Утилита для массового переименования сериалов (tv-shows) в указанный формат.

Идея применения такая:
- Размещаем весь сериал **в алфавитном порядке** серий по каталогам сезонов
- Запускаем с аргументами prefix и suffix (и другими по необходимости) на нужные каталоги

Аргументы:
- `-n` | `--name-filter` `FILTERS` - дополнительные фильтры для команды find, default: нет
- `-p` | `--prefix` `STRING` - шаблон имени до номера сезона/серии, default: прошлое имя файла
- `-s` | `--suffix` `STRING` - шаблон имени после номера сезона/серии, default: нет
- `-S` | `--season` `NUM` - фиксироанный номер сезона, default: нет
- `-E` | `--episode` `NUM` - фиксироанный номер эпизода, default: нет
- `--start-season` `NUM` - начинать номера сезонов с этого числа, default: 1
- `--start-episode` `NUM` - начинать номера эпизодов с этого числа, default: 1
- `-m` | `--maxdepth` `NUM` - максимальная глубина поиска для find, default: 1
- `-c` | `--check` - не выполнять переименование, только печатать
- `-d` | `--debug` - выводить выполняемую команду, если запущен с check
- `-f` | `--full-num` - сквозная нумерация серий в сезонах

Переменные окружения для паттернов нумерации:
- `$SEASON_PATTERN`, default: `S%02d`
- `$EPISODE_PATTERN`, default: `E%02d`

Примеры:
```bash
# Если надо - можем поменять паттерны генерации номеров сезонов и серий
export SEASON_PATTERN='S%02d'
export EPISODE_PATTERN='E%02d'

# Преименовываем все содержимое каталога по шаблону, при этом это только 2 сезон
cd /anime/Space.Battleship.Yamato/S02
# Сначала с check-ом
rename-tvs.sh --prefix Space.Battleship.Yamato.2202.OVA --suffix 1080p.BDRip.{tmdb-45844} --season 2 --check
rename-tvs.sh --prefix Space.Battleship.Yamato.2202.OVA --suffix 1080p.BDRip.{tmdb-45844} --season 2

# У первых двух сезонов Solo Leveling сквозная нумерация, применим full-num (f) и передадим сразу два каталога
rename-tvs.sh --prefix Solo.Leveling --suffix 1080p.BDRip --full-num "/anime/SL/TV-1" "/anime/SL/TV-2"

# А если мы хотим и сезон им приклеить первый обоим (формально они две части одного сезона), то так:
rename-tvs.sh --prefix Solo.Leveling --suffix 1080p.BDRip -f --season 1 "/anime/SL/TV-1" "/anime/SL/TV-2"

# А если мы хотим переименовать только второй сезон, но со сквозной нумерации с 13 серии, то так:
rename-tvs.sh --prefix Solo.Leveling --suffix 1080p.BDRip --season 2 --start-episode 13  "/anime/SL/TV-2"
```
