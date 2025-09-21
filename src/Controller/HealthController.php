<?php

declare(strict_types=1);

namespace App\Controller;

use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

final class HealthController
{
    public function __construct(
        #[Autowire(param: 'app.version')]
        private readonly string $appVersion,
    ) {
    }

    #[Route('/healthz', name: 'healthz', methods: ['GET'])]
    public function healthz(): JsonResponse
    {
        return new JsonResponse(['status' => 'ok']);
    }

    #[Route('/readyz', name: 'readyz', methods: ['GET'])]
    public function readyz(): JsonResponse
    {
        $checks = ['php_fpm' => true];
        $ready = true;

        return new JsonResponse([
            'ready' => $ready,
            'checks' => $checks,
            'version' => $this->appVersion,
        ], 200);
    }
}
