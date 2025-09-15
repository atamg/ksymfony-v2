<?php

declare(strict_types=1);

namespace App\Tests\Functional;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class HealthCheckTest extends WebTestCase
{
    // Functional tests for HealthController endpoints.

    public function testHealthzReturns200AndJson(): void
    {
        // Test /healthz endpoint returns 200 and expected JSON.
        $client = static::createClient();
        $client->request('GET', '/healthz');

        $this->assertResponseIsSuccessful();
        $this->assertJsonStringEqualsJsonString(
            '{"status":"ok"}',
            $client->getResponse()->getContent()
        );
    }

    public function testReadyzReturns200AndJson(): void
    {
        // Test /readyz endpoint returns 200 and valid JSON.
        $client = static::createClient();
        $client->request('GET', '/readyz');

        $this->assertResponseIsSuccessful();
        $this->assertJson($client->getResponse()->getContent());
    }
}
