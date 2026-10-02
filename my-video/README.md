# Remotion video

<p align="center">
  <a href="https://github.com/remotion-dev/logo">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://github.com/remotion-dev/logo/raw/main/animated-logo-banner-dark.apng">
      <img alt="Animated Remotion Logo" src="https://github.com/remotion-dev/logo/raw/main/animated-logo-banner-light.gif">
    </picture>
  </a>
</p>

Welcome to your Remotion project!

## Commands

**Install Dependencies**

```console
npm install
```

**Start Preview**

```console
npm run dev
```

**Render video**

```console
npx remotion render
```

**Upgrade Remotion**

```console
npx remotion upgrade
```

## Docs

Get started with Remotion by reading the [fundamentals page](https://www.remotion.dev/docs/the-fundamentals).

## Help

We provide help on our [Discord server](https://discord.gg/6VzzNDwUwV).

## Issues

Found an issue with Remotion? [File an issue here](https://github.com/remotion-dev/remotion/issues/new).

## License

Note that for some entities a company license is needed. [Read the terms here](https://github.com/remotion-dev/remotion/blob/main/LICENSE.md).

## Higgsfield

Generation scripts live in `scripts/` and use `@higgsfield/client`.

1. Copy `.env.example` to `.env` and set `HF_CREDENTIALS=KEY_ID:KEY_SECRET` (`.env` is gitignored).
2. Run a Genjutsu motion transfer (results are downloaded to `public/higgsfield/`):

```console
npm run hf:motion-transfer -- --video <url> --image <url> [--image <url> ...] [--prompt "..."] [--resolution 480p|720p|1080p]
```

Inputs must be public URLs. The source video must be at least 4s (anything past 30s is trimmed), with 1–8 image references.
Billing is per input second: $0.318 (480p), $0.681 (720p, default), $1.632 (1080p).
