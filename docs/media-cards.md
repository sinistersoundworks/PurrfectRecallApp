# Media card fields

Purrfect Recall flashcards support optional rich media on vocabulary-style cards:
images, IPA pronunciation, example sentences, and separate audio tracks for the
word, meaning, and example.

## Field mapping

| Concept | Purrfect Recall column | API JSON key |
|---------|------------------------|--------------|
| Word | `question` | `question` |
| Meaning | `answer` | `answer` |
| Example | `example` | `example` |
| IPA | `ipa` | `ipa` |
| Image | `image_path` | `image_path` |
| Word audio | `audio_word` | `audio_word` |
| Meaning audio | `audio_meaning` | `audio_meaning` |
| Example audio | `audio_example` | `audio_example` |

Paths are relative to the repo `media/` directory and served at `GET /media/{path}`.

## Upload new files

```bash
curl -F "file=@photo.jpg" http://127.0.0.1:8000/media/upload
# → {"path":"uploads/abc….jpg","url":"/media/uploads/abc….jpg"}
```

Use the returned `path` when creating or updating a flashcard.

## Importing Anki decks

A future importer can map `.apkg` note fields to these columns and extract media
files into `media/`. Import tooling is not included in this MVP.
