# FerrePlus chat IA with TypeSafe Jev

Implement TypeSafe Jev as the intent-classification provider for the authenticated FerrePlus chat while documenting the RAG flow in the video plan.

## Specs

1. **S1** — "agrega en la planificación el chat IA que es bastante importante."
2. **S2** — "para la clasificación de la intención vamos a usar un modelo que esta de moda por ser especializado para ese tipo de cosas el modelo es de jev de typesafe AI"
3. **S3** — "coloca una variable de entorno para alli colocarle la api key."
4. **S4** — Classification failures must preserve the existing safe fallback and must never execute an analytical query.

## Tasks

- T1 [S1] Add a dedicated Chat IA, embeddings and RAG chapter to `video-ferreplus/PLAN.md` — completed in working tree.
- T2 [S2-S4] Integrate TypeSafe Jev choice classification behind the Admin API — completed in working tree.
- T3 [S2-S4] Add configuration, tests, documentation and verification for the TypeSafe API key — completed in working tree; Maven unavailable in this environment.

## Log

L1: si porfa agrega en la planificación el chat IA que es bastante importante. Pero vamos a hacer un cambio igual de importante en el funcionamiento del chat, para la clasificación de la intención vamos a usar un modelo que esta de moda por ser especializado para ese tipo de cosas el modelo es de jev de typesafe AI coloca una variable de entorno para alli colocarle la api key. Me dices despues el nombre de la variable para yo colocarle la api_key

L2: TypeSafe Jev uses POST /v1/systemone with Bearer authentication, model `jev-latest`, and a closed choice question. The selected intent is returned by Jev; entity extraction for `ultimo_cambio` remains deterministic and fail-safe.
