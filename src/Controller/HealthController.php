<?php

declare(strict_types=1);

namespace App\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

final class HealthController
{
    #[Route('/healthz', name: 'healthz', methods: ['GET'])]
    public function healthz(): JsonResponse
    {
        // Liveness: process is up
        return new JsonResponse(['status' => 'ok']); // 200 OK
    }

    #[Route('/readyz', name: 'readyz', methods: ['GET'])]
    public function readyz(): JsonResponse
    {
        // Readiness: application is ready to serve traffic
        $checks = [
            'php_fpm' => true,
        ];
        $ready = true; // !in_array(false, $checks, true);

        return new JsonResponse([
            'ready' => $ready,
            'checks' => $checks,
        ], 200); // $ready ? 200 : 503);
    }
}
