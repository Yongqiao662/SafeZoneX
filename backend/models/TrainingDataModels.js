const mongoose = require('mongoose');

// Training Data Schemas for MongoDB

// Report Training Data Schema
const ReportTrainingSchema = new mongoose.Schema({
    text: {
        type: String,
        required: true,
        trim: true
    },
    isAuthentic: {
        type: Boolean,
        required: true
    },
    category: {
        type: String,
        enum: ['emergency', 'theft', 'vandalism', 'suspicious_activity', 'noise_complaint', 'other'],
        default: 'other'
    },
    source: {
        type: String,
        enum: ['user', 'admin', 'synthetic', 'government', 'news', 'social_media'],
        default: 'user'
    },
    verifiedBy: {
        type: String,
        default: 'system'
    },
    location: {
        latitude: Number,
        longitude: Number,
        address: String
    },
    metadata: {
        priority: String,
        userId: String,
        timestamp: Date,
        confidence: Number
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

// Threat Training Data Schema
const ThreatTrainingSchema = new mongoose.Schema({
    description: {
        type: String,
        required: true,
        trim: true
    },
    severity: {
        type: String,
        enum: ['low', 'medium', 'high', 'critical'],
        required: true
    },
    category: {
        type: String,
        enum: ['violence', 'theft', 'fire', 'medical', 'environmental', 'suspicious', 'other'],
        default: 'other'
    },
    location: {
        latitude: Number,
        longitude: Number,
        address: String,
        area: String
    },
    factors: [{
        factor: String,
        weight: Number
    }],
    metadata: {
        reportId: String,
        timestamp: Date,
        source: String,
        verified: Boolean
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

// Location Training Data Schema
const LocationTrainingSchema = new mongoose.Schema({
    coordinates: {
        latitude: {
            type: Number,
            required: true
        },
        longitude: {
            type: Number,
            required: true
        }
    },
    address: {
        type: String,
        required: true,
        trim: true
    },
    riskLevel: {
        type: String,
        enum: ['very_low', 'low', 'medium', 'high', 'very_high'],
        required: true
    },
    area: {
        type: String,
        trim: true
    },
    features: {
        crimeHistory: Number,
        timeOfDay: String,
        dayOfWeek: String,
        population: Number,
        lighting: String,
        security: String
    },
    incidents: [{
        type: String,
        date: Date,
        severity: String
    }],
    metadata: {
        dataSource: String,
        lastUpdated: Date,
        confidence: Number
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

// Model Training Status Schema
const ModelStatusSchema = new mongoose.Schema({
    modelType: {
        type: String,
        enum: ['reportAuthenticity', 'threatClassification', 'locationRisk'],
        required: true,
        unique: true
    },
    trained: {
        type: Boolean,
        default: false
    },
    accuracy: {
        type: Number,
        default: 0,
        min: 0,
        max: 1
    },
    trainingExamples: {
        type: Number,
        default: 0
    },
    lastTrained: {
        type: Date
    },
    modelData: {
        type: mongoose.Schema.Types.Mixed // Store serialized model data
    },
    version: {
        type: String,
        default: '1.0.0'
    },
    metadata: {
        trainingDuration: Number,
        hyperparameters: Object,
        validationResults: Object
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

// Bulk Training Data Import Schema
const BulkImportSchema = new mongoose.Schema({
    batchId: {
        type: String,
        required: true,
        unique: true
    },
    dataType: {
        type: String,
        enum: ['reports', 'threats', 'locations'],
        required: true
    },
    totalRecords: {
        type: Number,
        required: true
    },
    processedRecords: {
        type: Number,
        default: 0
    },
    status: {
        type: String,
        enum: ['pending', 'processing', 'completed', 'failed'],
        default: 'pending'
    },
    source: {
        type: String,
        required: true
    },
    errors: [{
        record: Number,
        error: String
    }],
    metadata: {
        fileName: String,
        uploadedBy: String,
        fileSize: Number
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    completedAt: Date
});

// Create Models
const ReportTraining = mongoose.model('ReportTraining', ReportTrainingSchema);
const ThreatTraining = mongoose.model('ThreatTraining', ThreatTrainingSchema);
const LocationTraining = mongoose.model('LocationTraining', LocationTrainingSchema);
const ModelStatus = mongoose.model('ModelStatus', ModelStatusSchema);
const BulkImport = mongoose.model('BulkImport', BulkImportSchema);

// Index definitions for better query performance
ReportTrainingSchema.index({ isAuthentic: 1, category: 1 });
ReportTrainingSchema.index({ createdAt: -1 });
ReportTrainingSchema.index({ source: 1 });

ThreatTrainingSchema.index({ severity: 1, category: 1 });
ThreatTrainingSchema.index({ 'location.latitude': 1, 'location.longitude': 1 });
ThreatTrainingSchema.index({ createdAt: -1 });

LocationTrainingSchema.index({ 'coordinates.latitude': 1, 'coordinates.longitude': 1 });
LocationTrainingSchema.index({ riskLevel: 1 });
LocationTrainingSchema.index({ area: 1 });

module.exports = {
    ReportTraining,
    ThreatTraining,
    LocationTraining,
    ModelStatus,
    BulkImport,
    // Export schemas for reference
    schemas: {
        ReportTrainingSchema,
        ThreatTrainingSchema,
        LocationTrainingSchema,
        ModelStatusSchema,
        BulkImportSchema
    }
};