<?php
$finder = PhpCsFixer\Finder::create()->in([__DIR__.'/src', __DIR__.'/tests']);
return (new PhpCsFixer\Config())
    ->setRiskyAllowed(true)
    ->setRules([
        '@Symfony' => true,
        'declare_strict_types' => true,
        'phpdoc_to_comment' => false,
    ])
    ->setFinder($finder);