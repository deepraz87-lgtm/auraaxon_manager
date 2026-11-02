const express = require('express');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

// In-memory "database" (Code-based mock DB instead of MySQL)
let products = [
  {
    id: 'API-PRD-001',
    name: 'Auraaxon Pro',
    version: 'v2.1.0',
    status: 'Active',
    releaseDate: '2023-10-15',
    category: 'Software',
    price: 299.99,
    description: 'Professional software suite for advanced brain-computer interfacing. Includes premium analytics and real-time visualization.',
    image_url: 'https://placehold.co/600x400/000000/FFFFFF/png?text=Auraaxon+Pro'
  },
  {
    id: 'API-PRD-002',
    name: 'Auraaxon Starter',
    version: 'v1.5.2',
    status: 'Active',
    releaseDate: '2023-08-22',
    category: 'Software',
    price: 99.99,
    description: 'Starter software tier for beginners exploring BCI technology. Essential features included.',
    image_url: 'https://placehold.co/600x400/000000/FFFFFF/png?text=Auraaxon+Starter'
  },
  {
    id: 'HW-PRD-001',
    name: 'Auraaxon Headset v1',
    version: 'v1.0.0',
    status: 'Active',
    releaseDate: '2024-01-10',
    category: 'Hardware',
    price: 4999.00,
    description: 'State-of-the-art non-invasive EEG headset with 32 channels. Ultra-low latency and high fidelity signal acquisition.',
    image_url: 'https://placehold.co/600x400/000000/FFFFFF/png?text=Auraaxon+Headset'
  },
  {
    id: 'HW-PRD-002',
    name: 'Auraaxon Sensor Pack',
    version: 'v1.2.0',
    status: 'Active',
    releaseDate: '2024-02-15',
    category: 'Hardware',
    price: 199.00,
    description: 'Replacement high-conductivity dry electrode sensor pack. Pack of 16 sensors.',
    image_url: 'https://placehold.co/600x400/000000/FFFFFF/png?text=Sensor+Pack'
  }
];

// GET /products - Fetch all products
app.get('/products', (req, res) => {
  res.json(products);
});

// POST /products - Add a new product
app.post('/products', (req, res) => {
  const { id, name, version, status, releaseDate, category, price, description, image_url } = req.body;
  
  const newProduct = {
    id,
    name,
    version,
    status,
    releaseDate,
    category: category || 'Software',
    price: price || 0,
    description: description || '',
    image_url: image_url || ''
  };
  
  products.push(newProduct);
  res.status(201).json({ message: 'Product added successfully', id });
});

// Start the server
app.listen(port, () => {
  console.log(`Backend server is running on http://localhost:${port}`);
});
