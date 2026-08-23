import { describe, expect, it } from 'vitest';
import { portadaMediaUrl } from './publicacion-list.component';

describe('portadaMediaUrl', () => {
  it('builds a same-origin URL only for supported object keys', () => {
    expect(portadaMediaUrl({ objectKey: '550e8400-e29b-41d4-a716-446655440000.webp' })).toBe(
      '/media/550e8400-e29b-41d4-a716-446655440000.webp'
    );
    expect(portadaMediaUrl({ objectKey: 'https://attacker.example/image.webp' })).toBeNull();
    expect(portadaMediaUrl(undefined)).toBeNull();
  });
});
