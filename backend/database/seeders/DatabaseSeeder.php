<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use App\Models\ReceiptSetting;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Demo owner
        $owner = User::create([
            'name' => 'Demo Owner',
            'email' => 'owner@bobkasir.test',
            'password' => Hash::make('password'),
            'role' => 'owner',
            'email_verified_at' => now(),
            'status' => 'active',
        ]);

        $tenant = Tenant::create([
            'owner_user_id' => $owner->id,
            'shop_name' => 'Kedai Kopi Demo',
            'shop_address' => 'Jl. Demo No. 1, Jakarta',
            'subscription_status' => 'trial',
            'trial_until' => now()->addDays(7),
        ]);

        $owner->update(['tenant_id' => $tenant->id]);

        // Demo admin
        User::create([
            'tenant_id' => $tenant->id,
            'name' => 'Demo Admin',
            'email' => 'admin@bobkasir.test',
            'password' => Hash::make('password'),
            'role' => 'admin',
            'email_verified_at' => now(),
            'status' => 'active',
            'created_by' => $owner->id,
        ]);

        // Demo cashier
        User::create([
            'tenant_id' => $tenant->id,
            'name' => 'Demo Kasir',
            'email' => 'kasir@bobkasir.test',
            'password' => Hash::make('password'),
            'role' => 'cashier',
            'email_verified_at' => now(),
            'status' => 'active',
            'created_by' => $owner->id,
        ]);

        // Categories
        $cat1 = Category::create(['tenant_id' => $tenant->id, 'name' => 'Klasik Kopi', 'order_index' => 1]);
        $cat2 = Category::create(['tenant_id' => $tenant->id, 'name' => 'Non-Kopi', 'order_index' => 2]);
        $cat3 = Category::create(['tenant_id' => $tenant->id, 'name' => 'Makanan', 'order_index' => 3]);

        // Products
        $products = [
            ['Americano', $cat1->id, 25000],
            ['Cappuccino', $cat1->id, 28000],
            ['Latte', $cat1->id, 30000],
            ['Espresso', $cat1->id, 22000],
            ['Matcha Latte', $cat2->id, 32000],
            ['Teh Tarik', $cat2->id, 20000],
            ['Coklat Susu', $cat2->id, 28000],
            ['Roti Bakar', $cat3->id, 18000],
            ['Nasi Goreng', $cat3->id, 35000],
        ];

        foreach ($products as [$name, $catId, $price]) {
            Product::create([
                'tenant_id' => $tenant->id,
                'category_id' => $catId,
                'name' => $name,
                'price' => $price,
                'is_active' => true,
            ]);
        }

        // Receipt settings
        ReceiptSetting::create([
            'tenant_id' => $tenant->id,
            'shop_name' => 'Kedai Kopi Demo',
            'shop_address' => 'Jl. Demo No. 1, Jakarta',
            'footer_text' => 'Terima kasih telah berkunjung!',
            'paper_width' => '58',
            'cash_drawer_enabled' => false,
        ]);
    }
}
