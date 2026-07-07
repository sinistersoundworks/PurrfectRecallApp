# Media card fields ( layout)

Purrfect Recall flashcards support optional rich media, modeled on the
[](https://ankiweb.net) deck structure shown in
`app_scheme_images/ (all books) [en-en] - AnkiWeb.pdf`.

## Field mapping

| Anki /  field | Purrfect Recall column | API JSON key       |
|-----------------------|-------------------|--------------------|
| Word                  | `question`        | `question`         |
| Meaning               | `answer`          | `answer`           |
| Example               | `example`         | `example`          |
| IPA                   | `ipa`             | `ipa`              |
| Image                 | `image_path`      | `image_path`       |
| Sound (word)          | `audio_word`      | `audio_word`       |
| Sound_Meaning         | `audio_meaning`   | `audio_meaning`    |
| Sound_Example         | `audio_example`   | `audio_example`    |

Paths are relative to the repo `media/` directory and served at `GET /media/{path}`.

## Upload new files

```bash
curl -F "file=@photo.jpg" http://127.0.0.1:8000/media/upload
# → {"path":"uploads/abc….jpg","url":"/media/uploads/abc….jpg"}
```

Use the returned `path` when creating or updating a flashcard.

## Sample deck

```bash
uv run python scripts/add_flashcard_media_columns.py
uv run python scripts/
```

Creates **** with five vocabulary cards and placeholder image/audio files under `media/samples//`.

## Importing a full Anki deck

A future importer can map `.apkg` note fields to these columns and extract media files into `media/`. The PDF reference deck ships ~3,871 images and ~11,073 audio files — import tooling is not included in this MVP.
