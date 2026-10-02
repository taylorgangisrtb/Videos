// Genjutsu motion transfer: applies the motion from a video onto the subject in an image.
// Usage: npm run hf:motion-transfer -- <video_url> <image_url> [prompt] [resolution]
import { higgsfield, downloadToPublic } from "./higgsfield.mjs";

const [videoUrl, imageUrl, prompt = "", resolution = "720p"] =
  process.argv.slice(2);

if (!videoUrl || !imageUrl) {
  console.error(
    "Usage: npm run hf:motion-transfer -- <video_url> <image_url> [prompt] [resolution]",
  );
  process.exit(1);
}

const result = await higgsfield.subscribe(
  "higgsfield/genjutsu/motion-transfer/v1.0",
  {
    input: {
      prompt,
      video_url: videoUrl,
      image_urls: [imageUrl],
      resolution,
    },
    withPolling: true,
  },
);

console.log(result);

if (result.status !== "completed" || !result.video?.url) {
  console.error(`Generation did not complete (status: ${result.status}).`);
  process.exit(1);
}

const saved = await downloadToPublic(
  result.video.url,
  `motion-transfer-${result.request_id}.mp4`,
);
console.log(
  `Saved to ${saved} — use staticFile("higgsfield/${saved.split("/").pop()}")`,
);
