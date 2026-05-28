import express from 'express';
import { getConfigValue } from '../util.js';

const router = express.Router();

const CACHE = new Map();
const MAX_CACHE_SIZE = Number(getConfigValue('imageProxy.cacheSize', 200, 'number'));
const CACHE_TTL = Number(getConfigValue('imageProxy.cacheTTL', 3600000, 'number')); // 1 hour

router.get('/', async (req, res) => {
    try {
        const url = req.query.url;
        if (!url) {
            return res.status(400).send('Missing url parameter');
        }

        const cacheKey = url;
        const cached = CACHE.get(cacheKey);
        if (cached && (Date.now() - cached.timestamp) < CACHE_TTL) {
            res.setHeader('Content-Type', cached.contentType);
            res.setHeader('X-Proxy-Cache', 'HIT');
            return res.send(cached.data);
        }

        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 10000);

        const response = await fetch(url, { signal: controller.signal });
        clearTimeout(timeout);

        if (!response.ok) {
            return res.status(response.status).send('Failed to fetch image');
        }

        const contentType = response.headers.get('content-type') || 'image/png';
        const buffer = Buffer.from(await response.arrayBuffer());

        // Cache the image
        if (CACHE.size >= MAX_CACHE_SIZE) {
            const firstKey = CACHE.keys().next().value;
            CACHE.delete(firstKey);
        }
        CACHE.set(cacheKey, { data: buffer, contentType, timestamp: Date.now() });

        res.setHeader('Content-Type', contentType);
        res.setHeader('Cache-Control', 'public, max-age=3600');
        res.setHeader('X-Proxy-Cache', 'MISS');
        res.send(buffer);
    } catch (error) {
        console.error('Image proxy error:', error.message);
        res.status(500).send('Image proxy error');
    }
});

export { router };
