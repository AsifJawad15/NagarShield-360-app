export function PrivateMedia({ mediaKey, alt, controls = false }: { mediaKey: string; alt: string; controls?: boolean }) {
  const url = `/api/media/${mediaKey.split('/').map(encodeURIComponent).join('/')}`
  if (mediaKey.endsWith('.webm') || mediaKey.endsWith('.mp4')) {
    const poster = `/api/media/${mediaKey.replace(/\.webm$/, '.svg').split('/').map(encodeURIComponent).join('/')}`
    return <video src={url} poster={mediaKey.endsWith('.webm') ? poster : undefined} controls={controls} playsInline preload="metadata" aria-label={alt} />
  }
  return <img src={url} alt={alt} />
}
