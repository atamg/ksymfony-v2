<?php

declare(strict_types=1);

namespace App\Tests\Functional;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class HealthCheckTest extends WebTestCase
{
    private function expectedVersion(): string
    {
        // Mirror controller's default: APP_VERSION or "unknown" if not set/empty.
        $v = $_ENV['APP_VERSION'] ?? $_SERVER['APP_VERSION'] ?? null;

        return (null !== $v && '' !== $v) ? $v : 'unknown';
    }

    public function testHealthzReturns200AndJson(): void
    {
        $client = static::createClient();
        $client->request('GET', '/healthz');

        self::assertResponseIsSuccessful();
        self::assertJsonStringEqualsJsonString(
            '{"status":"ok"}',
            $client->getResponse()->getContent()
        );
    }

    public function testReadyzReturns200JsonWithVersion(): void
    {
        $client = static::createClient();
        $client->request('GET', '/readyz');

        self::assertResponseIsSuccessful();

        $payload = json_decode($client->getResponse()->getContent(), true, 512, JSON_THROW_ON_ERROR);

        self::assertIsArray($payload, 'readyz returns JSON object');
        self::assertArrayHasKey('ready', $payload);
        self::assertArrayHasKey('checks', $payload);
        self::assertArrayHasKey('version', $payload);

        self::assertTrue($payload['ready'], 'ready flag should be true for healthy app');
        self::assertIsArray($payload['checks']);
        self::assertArrayHasKey('php_fpm', $payload['checks']);
        self::assertTrue($payload['checks']['php_fpm']);

        self::assertSame($this->expectedVersion(), $payload['version'], 'version must match APP_VERSION or "unknown"');
    }
}
