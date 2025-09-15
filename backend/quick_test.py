"""
Simple Test Tool for SafeZoneX High-Accuracy ML Model
Test your own text to see if it's classified as real or fake
"""
import joblib
import json

def load_model():
    """Load the high-accuracy model"""
    try:
        model = joblib.load('safety_report_classifier_high_accuracy.pkl')
        vectorizer = joblib.load('tfidf_vectorizer_high_accuracy.pkl')
        
        with open('model_metadata_high_accuracy.json', 'r') as f:
            metadata = json.load(f)
            
        print("✅ High-accuracy model loaded successfully!")
        print(f"📊 Model: {metadata['model_name']}")
        print(f"📊 Accuracy: {metadata['test_accuracy']:.1%}")
        print(f"📊 Dataset: {metadata['dataset_size']} examples")
        print("-" * 50)
        
        return model, vectorizer
    except Exception as e:
        print(f"❌ Error loading model: {e}")
        return None, None

def test_text(model, vectorizer, text):
    """Test a single text and return prediction"""
    
    # Transform text
    X = vectorizer.transform([text])
    
    # Get prediction and probabilities
    prediction = model.predict(X)[0]
    probabilities = model.predict_proba(X)[0]
    
    # Get confidence
    confidence = max(probabilities)
    
    # Get individual class probabilities
    classes = model.classes_
    prob_dict = dict(zip(classes, probabilities))
    
    return prediction, confidence, prob_dict

def main():
    """Main testing interface"""
    
    print("🧪 SafeZoneX ML Model - Quick Test Tool")
    print("=" * 50)
    
    # Load model
    model, vectorizer = load_model()
    if not model:
        return
    
    print("\nInstructions:")
    print("• Type your safety report text to test")
    print("• Type 'quit' to exit")
    print("• Type 'examples' to see test examples")
    
    while True:
        print("\n" + "="*50)
        user_input = input("📝 Enter text to test: ").strip()
        
        if user_input.lower() in ['quit', 'exit', 'q']:
            print("👋 Goodbye!")
            break
        
        if user_input.lower() == 'examples':
            show_examples(model, vectorizer)
            continue
            
        if not user_input:
            print("❌ Please enter some text")
            continue
        
        # Test the text
        prediction, confidence, prob_dict = test_text(model, vectorizer, user_input)
        
        # Display results
        print(f"\n🎯 RESULT:")
        print(f"   Text: '{user_input[:60]}{'...' if len(user_input) > 60 else ''}'")
        print(f"   Prediction: {prediction.upper()}")
        print(f"   Confidence: {confidence:.1%}")
        
        # Show probability breakdown
        print(f"\n📊 Probabilities:")
        for cls, prob in prob_dict.items():
            bar_length = int(prob * 20)
            bar = "█" * bar_length + "░" * (20 - bar_length)
            print(f"   {cls.upper()}: {prob:.1%} [{bar}]")
        
        # Interpretation
        if prediction == 'real':
            if confidence >= 0.8:
                status = "✅ HIGH CONFIDENCE - Likely authentic safety report"
            elif confidence >= 0.6:
                status = "⚠️ MEDIUM CONFIDENCE - Probably authentic"
            else:
                status = "❓ LOW CONFIDENCE - Uncertain, needs review"
        else:  # fake
            if confidence >= 0.8:
                status = "🚨 HIGH CONFIDENCE - Likely spam/fake report"
            elif confidence >= 0.6:
                status = "⚠️ MEDIUM CONFIDENCE - Probably fake"
            else:
                status = "❓ LOW CONFIDENCE - Uncertain classification"
        
        print(f"\n💡 Assessment: {status}")

def show_examples(model, vectorizer):
    """Show example tests"""
    
    print("\n🧪 EXAMPLE TESTS:")
    print("-" * 30)
    
    examples = [
        ("Real Safety Report", "Someone broke into my dorm room last night and stole my laptop and books"),
        ("Real Emergency", "Gas leak detected in dining hall, students evacuating immediately"),
        ("Real Harassment", "Professor making inappropriate comments to female students in class"),
        ("Fake Spam", "WIN $5000 NOW! Click here for free money! Limited time offer!"),
        ("Fake Marketing", "Lose weight fast with miracle pills! No diet needed!"),
        ("Fake Nonsense", "Purple unicorns flying around campus with rainbow wings")
    ]
    
    for category, text in examples:
        prediction, confidence, _ = test_text(model, vectorizer, text)
        
        # Check if prediction matches expected
        expected_real = category.startswith("Real")
        is_correct = (expected_real and prediction == "real") or (not expected_real and prediction == "fake")
        status = "✅" if is_correct else "❌"
        
        print(f"\n{status} {category}:")
        print(f"   Text: '{text}'")
        print(f"   Result: {prediction.upper()} ({confidence:.1%})")

if __name__ == "__main__":
    main()