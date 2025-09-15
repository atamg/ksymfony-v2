<?php

declare(strict_types=1);

namespace App;

use Symfony\Bundle\FrameworkBundle\Kernel\MicroKernelTrait;
use Symfony\Component\HttpKernel\Kernel as BaseKernel;

// Kernel is the main entry point for the Symfony application.
// It bootstraps the framework and loads configuration.
class Kernel extends BaseKernel
{
    use MicroKernelTrait;
}
