<?php

declare(strict_types=1);

namespace App\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

// HealthController provides endpoints for liveness and readiness probes.
final class HealthController
{
    #[Route('/healthz', name: 'healthz', methods: ['GET'])]
    public function healthz(): JsonResponse
    {
        // Liveness: returns OK if the process is running.
        return new JsonResponse(['status' => 'ok']); // 200 OK
    }

    #[Route('/readyz', name: 'readyz', methods: ['GET'])]
    public function readyz(): JsonResponse
    {
        // Readiness: checks if the app is ready to serve traffic.
        // Add more checks here as needed (e.g., DB, cache).
        $checks = [
            'php_fpm' => true, // Example check: PHP-FPM is up
        ];
        $ready = true; // Set to false if any check fails
        // !in_array(false, $checks, true);

        return new JsonResponse([
            'ready' => $ready,
            'checks' => $checks,
        ], 200); // $ready ? 200 : 503);
    }
}
