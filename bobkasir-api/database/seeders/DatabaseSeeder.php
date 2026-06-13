<?php

namespace Database\Seeders;

use App\Models\SubscriptionPlan;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Subscription plans
        SubscriptionPlan::upsert([
            ['id' => '01000000-0000-0000-0000-000000000001', 'name' => 'Mingguan', 'slug' => 'weekly',  'price' => 30000,  'duration_days' => 7,  'is_active' => true],
            ['id' => '01000000-0000-0000-0000-000000000002', 'name' => 'Bulanan',  'slug' => 'monthly', 'price' => 100000, 'duration_days' => 30, 'is_active' => true],
        ], ['slug'], ['name', 'price', 'duration_days', 'is_active']);

        $this->command->info('BobKasir database seeded.');
    }
}
