// Genjutsu motion transfer: restyles a source video with 1–8 image references,
// keeping the original motion, camera movement and timing.
// Source video must be ≥4s (trimmed to 30s). Billed per input second:
// $0.318 (480p), $0.681 (720p), $1.632 (1080p).
// Usage: npm run hf:motion-transfer -- --video <url> --image <url> [--image <url> ...]
//          [--prompt "..."] [--resolution 480p|720p|1080p]
import { parseArgs } from "node:util";
import { higgsfield, downloadToPublic } from "./higgsfield.mjs";

const USAGE =
  'Usage: npm run hf:motion-transfer -- --video <url> --image <url> [--image <url> ...] [--prompt "..."] [--resolution 480p|720p|1080p]';
const RESOLUTIONS = ["480p", "720p", "1080p"];

const fail = (message) => {
  console.error(message);
  process.exit(1);
};

const { values } = parseArgs({
  options: {
    video: { type: "string" },
    image: { type: "string", multiple: true, default: [] },
    prompt: { type: "string", default: "" },
    resolution: { type: "string", default: "720p" },
  },
});

if (!values.video || values.image.length === 0) {
  fail(USAGE);
}
if (values.image.length > 8) {
  fail("Genjutsu accepts at most 8 image references.");
}
if (!RESOLUTIONS.includes(values.resolution)) {
  fail(`--resolution must be one of ${RESOLUTIONS.join(", ")}.`);
}

const result = await higgsfield.subscribe(
  "higgsfield/genjutsu/motion-transfer/v1.0",
  {
    input: {
      prompt: values.prompt,
      video_url: values.video,
      image_urls: values.image,
      resolution: values.resolution,
    },
    withPolling: true,
  },
);

console.log(result);

if (result.status !== "completed" || !result.video?.url) {
  const reason = result.error ? `: ${result.error}` : "";
  fail(
    `Request ${result.request_id} ended with status "${result.status}"${reason}`,
  );
}

const fileName = `motion-transfer-${result.request_id}.mp4`;
const saved = await downloadToPublic(result.video.url, fileName);
console.log(`Saved to ${saved} — use staticFile("higgsfield/${fileName}")`);
