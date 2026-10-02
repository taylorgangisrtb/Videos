// Shared Higgsfield client setup + helpers for generation scripts.
// Credentials come from HF_CREDENTIALS ("KEY_ID:KEY_SECRET"), e.g. via a local .env.
import { config, higgsfield } from "@higgsfield/client/v2";
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

if (!process.env.HF_CREDENTIALS) {
  console.error(
    "Missing HF_CREDENTIALS. Set it in .env (see .env.example) or your environment.",
  );
  process.exit(1);
}

config({
  credentials: process.env.HF_CREDENTIALS,
});

export { higgsfield };

// Downloads a generated asset into public/ so Remotion can use it via staticFile().
export const downloadToPublic = async (url, fileName) => {
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Download failed (${res.status}) for ${url}`);
  }
  const outPath = path.join("public", "higgsfield", fileName);
  await mkdir(path.dirname(outPath), { recursive: true });
  await writeFile(outPath, Buffer.from(await res.arrayBuffer()));
  return outPath;
};
