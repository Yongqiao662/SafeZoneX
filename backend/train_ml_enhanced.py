import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import joblib
import json
from datetime import datetime
import requests

print("🐍 SafeZoneX ML Training - Enhanced Dataset with Flutter Categories")
print("=" * 70)

def create_comprehensive_dataset():
    """Create a comprehensive dataset with Flutter app categories and more examples"""
    print("📝 Creating comprehensive safety report dataset...")
    
    # Real safety reports - categorized according to Flutter app
    real_reports = {
        'Suspicious Person': [
            "Person has been loitering outside the dormitory for over an hour watching students",
            "Unknown individual following female students from library to parking lot",
            "Someone taking photos of students without permission near the cafeteria",
            "Man in dark clothing hiding behind trees observing the sports complex",
            "Stranger asking students personal questions about their schedules and dorm rooms",
            "Person trying to look into dormitory windows using binoculars",
            "Individual wearing mask and hood acting suspiciously near the main gate",
            "Someone sitting in car for hours watching students enter and exit buildings",
            "Person dressed as maintenance worker but no ID badge accessing restricted areas",
            "Unknown individual trying to follow students into secured dormitory buildings",
            "Suspicious person filming students in changing areas near gymnasium",
            "Someone approaching multiple students asking for money with aggressive behavior",
            "Person leaving packages near building entrances and walking away quickly",
            "Individual pretending to be lost but clearly observing security camera locations",
            "Stranger offering rides to students late at night near campus exits"
        ],
        
        'Theft/Robbery': [
            "Witnessed someone breaking into cars in parking lot B using tools",
            "Student's laptop stolen from library table while they went to restroom",
            "Bike theft in progress at the bicycle rack near engineering building",
            "Someone breaking into lockers in the gymnasium changing room",
            "Purse snatching incident near the ATM at student union building",
            "Attempted robbery of student walking alone between dormitories at night",
            "Multiple phones stolen from tables during busy cafeteria lunch hour",
            "Witnessed theft of textbooks from unattended backpack in lecture hall",
            "Someone forcing open vending machine to steal money and snacks",
            "Group of individuals robbing student near dark parking area",
            "Theft of scientific equipment from unlocked laboratory room",
            "Someone stealing packages from dormitory mail room",
            "Witnessed wallet pickpocketing on crowded campus shuttle bus",
            "Attempted break-in to professor's office during evening hours",
            "Student's expensive calculator stolen during exam in mathematics building"
        ],
        
        'Vandalism': [
            "Graffiti spray painted on library exterior walls overnight",
            "Windows broken in student union building with rocks",
            "Vandalism of campus statues with permanent marker drawings",
            "Someone keying cars systematically in visitor parking lot",
            "Destruction of flower beds and landscaping near administration building",
            "Bathroom mirrors smashed and walls damaged in dormitory facilities",
            "Campus signs torn down and thrown into nearby pond",
            "Elevator buttons and panels damaged with sharp objects",
            "Graffiti covering emergency exit signs making them unreadable",
            "Deliberate damage to outdoor exercise equipment in recreation area",
            "Someone pouring paint on building steps and handrails",
            "Destruction of outdoor bulletin boards and posted announcements",
            "Vandalism of campus artwork and memorial installations",
            "Windows etched with inappropriate messages using sharp objects",
            "Damage to campus lighting fixtures causing safety hazards"
        ],
        
        'Drug Activity': [
            "Suspected drug transaction observed behind chemistry building",
            "Strong smell of marijuana coming from specific dormitory room",
            "Students acting erratically after visiting certain individual's room",
            "Packages being exchanged for money in secluded area near parking",
            "Suspected drug paraphernalia found in bathroom stalls",
            "Individual selling pills to students near recreational facilities",
            "Group gathering late at night passing around suspicious substances",
            "Student found unconscious with drug paraphernalia nearby",
            "Frequent visitors to dormitory room at odd hours for brief periods",
            "Suspicious white powder residue found on tables in study areas",
            "Student dealing drugs from car parked near campus entrance",
            "Strange chemical smells coming from dormitory basement area",
            "Multiple students visiting same room and leaving quickly",
            "Drug-related items discovered in outdoor smoking areas",
            "Suspected drug manufacturing setup in abandoned campus building"
        ],
        
        'Harassment': [
            "Student being verbally harassed based on race near library entrance",
            "Sexual harassment of female student by male student in elevator",
            "Cyberbullying messages and threats posted on campus social media",
            "Professor making inappropriate comments to students during office hours",
            "Group of students bullying international student in cafeteria",
            "Repeated unwanted advances despite clear rejection from victim",
            "Harassment based on sexual orientation in dormitory common areas",
            "Student receiving threatening messages on phone and social media",
            "Inappropriate touching and sexual comments in crowded areas",
            "Verbal abuse and discriminatory slurs during sports events",
            "Stalking behavior with repeated unwanted contact and following",
            "Workplace harassment of campus staff by supervisor",
            "Religious discrimination and harassment in campus organizations",
            "Physical intimidation and threats over academic competition",
            "Online harassment through sharing private photos without consent"
        ],
        
        'Safety Hazard': [
            "Broken stairs with missing handrail creating fall risk",
            "Exposed electrical wires dangling from ceiling in hallway",
            "Large pothole in main walkway causing students to trip",
            "Ice formation on campus walkways making them extremely slippery",
            "Broken glass scattered across recreational area where students exercise",
            "Malfunctioning elevator dropping between floors with people inside",
            "Gas leak smell detected near campus restaurant kitchen area",
            "Unstable tree branch hanging over main pedestrian pathway",
            "Chemical spill in laboratory creating toxic fume exposure risk",
            "Broken water pipe causing flooding and electrical hazards",
            "Damaged fire escape ladder that could collapse if used",
            "Construction equipment blocking emergency exit routes",
            "Poisonous plants growing in areas where children play",
            "Weak railing on bridge over campus pond posing fall danger",
            "Asbestos exposure risk from damaged ceiling tiles in old building"
        ],
        
        'Unauthorized Access': [
            "Unknown person gained access to restricted laboratory using stolen keycard",
            "Individual without proper credentials entered faculty-only building",
            "Someone accessing rooftop areas that are clearly marked off-limits",
            "Unauthorized person in dormitory after hours without guest registration",
            "Individual breaking into maintenance areas and tampering with equipment",
            "Non-student accessing computer lab during closed hours",
            "Person entering restricted parking area without proper permits",
            "Unauthorized access to campus radio station broadcasting equipment",
            "Individual in administrative offices without appointment or authorization",
            "Someone accessing chemistry storage areas with dangerous materials",
            "Unauthorized person in sports facility equipment storage room",
            "Individual entering library restricted archives without permission",
            "Person accessing campus network server room without authorization",
            "Unauthorized individual in campus daycare facility near children",
            "Someone entering medical clinic areas without proper clearance"
        ],
        
        'Other': [
            "Loud music from dormitory keeping entire floor awake past quiet hours",
            "Unusual smell and smoke coming from campus kitchen ventilation",
            "Lost child found wandering campus during large campus event",
            "Injured animal on campus grounds requiring wildlife rescue assistance",
            "Power outage affecting multiple campus buildings simultaneously",
            "Water main break causing campus-wide water shortage emergency",
            "Severe weather damage to campus buildings requiring immediate attention",
            "Medical emergency with student collapse during outdoor sports event",
            "Campus Wi-Fi network compromised with suspicious activity detected",
            "Food poisoning outbreak suspected from campus dining facility",
            "Campus transportation breakdown stranding students in remote area",
            "Unusual drone activity over sensitive campus research facilities",
            "Campus emergency alert system malfunction during actual emergency",
            "Strange chemical reaction in laboratory creating unexpected situation",
            "Campus social media accounts hacked posting inappropriate content"
        ]
    }
    
    # Fake/spam reports (much more varied to increase challenge)
    fake_reports = [
        # Obvious spam/scams
        "CONGRATULATIONS! You have won $50,000 in our university lottery! Click this link immediately to claim your prize!",
        "Make $5000 per week working from your dorm room! No experience required! Students love this opportunity!",
        "FREE iPhone 15 for first 100 students! Just pay $9.99 shipping! Limited time offer expires today!",
        "Your student account has been compromised! Click here and enter your password to secure it now!",
        "URGENT: IRS investigation! You owe $15,000 in taxes! Pay immediately or face arrest warrant!",
        "Hot singles in your area want to meet university students! Create profile now and start dating!",
        "Your computer has 47 viruses! Download our security software immediately to protect your data!",
        "Nigerian prince needs help transferring $10 million! You will receive 10% for helping!",
        "MIRACLE weight loss pill! Lose 30 pounds in 10 days! Doctors don't want you to know this secret!",
        "Work from home! Earn $200 per day just by posting on social media! No skills needed!",
        
        # Commercial advertisements 
        "Best pizza deals for students! Order now and get 50% off your first purchase plus free delivery!",
        "Cheap textbooks for all subjects! Save hundreds of dollars! Contact us for best deals on campus!",
        "Professional tutoring services available! Guaranteed grade improvement or full refund! Call now!",
        "Spring break vacation packages! Cancun trip for only $299! Book now before prices increase!",
        "Designer clothing sale! 70% off all items! Perfect for college students on budget!",
        "Car insurance for students! Lowest rates guaranteed! Get quote now and save money!",
        "Apartment rentals near campus! Luxury living for affordable prices! Move in today!",
        "Student credit cards with no fees! Build credit while in college! Apply online now!",
        "Energy drinks bulk sale! Stay awake for finals! Case of 24 for only $20!",
        "Graduation photography packages! Professional photos at student prices! Book your session!",
        
        # Fake emergencies/pranks
        "BREAKING: Zombie outbreak starting in cafeteria! Everyone run for your lives! Not a drill!",
        "UFO landing on football field! Aliens requesting to speak with university president!",
        "Free money fountain activated in main quad! Bring buckets to collect cash!",
        "University cancelled forever! No more classes or exams! Party time for everyone!",
        "Giant meteor heading toward campus! Evacuation required in 30 minutes!",
        "Time machine discovered in physics building! Students can go back and fix grades!",
        "Dinosaurs escaped from geology museum! T-Rex spotted near student union!",
        "Campus turned into movie set! All students will be paid extras in Hollywood film!",
        "Magic portal opened in library! Free transportation to any destination worldwide!",
        "University selling campus for $1! Students can buy buildings and become landlords!",
        
        # Phishing/security threats
        "Security alert! Your student email will be deleted! Verify account by clicking link!",
        "Bank notice: Your account frozen! Update information immediately to restore access!",
        "Netflix subscription expired! Re-enter credit card details to continue watching shows!",
        "Amazon package delivery failed! Click link to reschedule delivery to dorm room!",
        "Social media account hacked! Click here to secure and change your password now!",
        "University scholarship available! Fill out form with personal information to apply!",
        "COVID-19 contact tracing! Click link to report your recent locations and contacts!",
        "Campus parking permit renewal! Enter credit card information to avoid towing!",
        "Library fine payment! Your account is overdue! Pay online to avoid collection agency!",
        "Student loan forgiveness program! Enter SSN and bank details to qualify now!",
        
        # Chain letters/forwards
        "Send this message to 10 people or have bad luck for 7 years! My friend ignored it and failed!",
        "Share if you love your parents! Ignore if you don't care about family! 1 share = 1 prayer!",
        "This message contains virus that activates if not forwarded! Protect computer by sharing!",
        "Secret government conspiracy revealed! Share before they delete it! Truth must be known!",
        "Prayer chain for sick student! Share to show you care! Every share = one prayer!",
        "Lucky message! Share with 5 friends and money will come to you within 24 hours!",
        "Warning! New virus spreading through campus! Forward this to protect your friends!",
        "Share this message to 20 people and your crush will text you today! Really works!",
        "Ghost story: Share or she will visit you tonight! True story that happened to my friend!",
        "Math problem only geniuses can solve! Share if you got the answer! Test your IQ!"
    ]
    
    # Create balanced dataset
    data = []
    
    # Add real reports
    for category, reports in real_reports.items():
        for report in reports:
            data.append({
                'content': report,
                'label': 'real',
                'category': category,
                'flutter_category': category  # Maps directly to Flutter app categories
            })
    
    # Add fake reports
    for report in fake_reports:
        data.append({
            'content': report,
            'label': 'fake',
            'category': 'spam',
            'flutter_category': 'Other'  # All fake reports go to 'Other'
        })
    
    df = pd.DataFrame(data)
    
    # Shuffle the dataset
    df = df.sample(frac=1, random_state=42).reset_index(drop=True)
    
    print(f"✅ Comprehensive dataset created: {len(df)} examples")
    print(f"   - Real reports: {len(df[df['label'] == 'real'])}")
    print(f"   - Fake reports: {len(df[df['label'] == 'fake'])}")
    
    # Show category distribution
    print("\n📊 Real Report Categories (matching Flutter app):")
    real_df = df[df['label'] == 'real']
    for category in real_reports.keys():
        count = len(real_df[real_df['category'] == category])
        print(f"   - {category}: {count} examples")
    
    return df

def train_enhanced_models(df):
    """Train models with enhanced dataset"""
    print("\n🤖 Training Enhanced ML Models...")
    
    # Prepare features and labels
    X = df['content']
    y = df['label']
    
    # Split data with stratification
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.25, random_state=42, stratify=y  # Larger test set
    )
    
    print(f"📊 Training set: {len(X_train)} examples")
    print(f"📊 Test set: {len(X_test)} examples")
    
    # Enhanced text vectorization
    print("🔤 Vectorizing text with enhanced TF-IDF...")
    vectorizer = TfidfVectorizer(
        max_features=2000,  # Increased features
        stop_words='english',
        ngram_range=(1, 3),  # Include trigrams
        min_df=2,  # Minimum document frequency
        max_df=0.8,  # Maximum document frequency
        lowercase=True,
        strip_accents='unicode'
    )
    
    X_train_vec = vectorizer.fit_transform(X_train)
    X_test_vec = vectorizer.transform(X_test)
    
    print(f"🔤 Feature dimensions: {X_train_vec.shape[1]}")
    
    # Enhanced models with better parameters
    models = {
        'Naive Bayes': MultinomialNB(alpha=0.5),  # Reduced smoothing
        'Logistic Regression': LogisticRegression(
            random_state=42, 
            max_iter=2000,
            C=2.0,  # Less regularization
            penalty='l2',
            solver='liblinear'
        ),
        'Random Forest': RandomForestClassifier(
            n_estimators=100,  # More trees
            random_state=42,
            max_depth=15,  # Deeper trees
            min_samples_split=3,
            min_samples_leaf=1,
            max_features='sqrt'
        )
    }
    
    results = {}
    
    for name, model in models.items():
        print(f"\n🔧 Training {name}...")
        
        # Train model
        model.fit(X_train_vec, y_train)
        
        # Cross-validation with stratification
        cv_scores = cross_val_score(
            model, X_train_vec, y_train, 
            cv=10, scoring='accuracy', 
            n_jobs=-1  # Use all cores
        )
        
        # Test predictions
        y_pred = model.predict(X_test_vec)
        test_accuracy = accuracy_score(y_test, y_pred)
        
        # Detailed evaluation
        class_report = classification_report(y_test, y_pred, output_dict=True)
        conf_matrix = confusion_matrix(y_test, y_pred)
        
        results[name] = {
            'model': model,
            'cv_mean': cv_scores.mean(),
            'cv_std': cv_scores.std(),
            'test_accuracy': test_accuracy,
            'classification_report': class_report,
            'confusion_matrix': conf_matrix.tolist(),
            'cv_scores': cv_scores.tolist()
        }
        
        print(f"   Cross-validation: {cv_scores.mean():.3f} ± {cv_scores.std():.3f}")
        print(f"   Test accuracy: {test_accuracy:.3f}")
        print(f"   Precision (real): {class_report['real']['precision']:.3f}")
        print(f"   Recall (real): {class_report['real']['recall']:.3f}")
        print(f"   F1-score (real): {class_report['real']['f1-score']:.3f}")
        print(f"   Precision (fake): {class_report['fake']['precision']:.3f}")
        print(f"   Recall (fake): {class_report['fake']['recall']:.3f}")
        print(f"   F1-score (fake): {class_report['fake']['f1-score']:.3f}")
    
    # Select best model
    best_model_name = max(results.keys(), key=lambda k: results[k]['cv_mean'])
    best_model = results[best_model_name]['model']
    
    print(f"\n🏆 Best model: {best_model_name}")
    print(f"   CV accuracy: {results[best_model_name]['cv_mean']:.3f} ± {results[best_model_name]['cv_std']:.3f}")
    print(f"   Test accuracy: {results[best_model_name]['test_accuracy']:.3f}")
    
    return best_model, vectorizer, results, best_model_name

def test_flutter_categories(model, vectorizer):
    """Test model with examples from each Flutter category"""
    print(f"\n🎯 Testing with Flutter App Categories...")
    
    flutter_test_cases = {
        'Suspicious Person': [
            "Unknown person has been watching students and taking photos near dormitory entrance",
            "Individual following female students from parking lot and asking personal questions"
        ],
        'Theft/Robbery': [
            "Witnessed laptop theft from library table while student was in bathroom",
            "Group of people breaking into cars in parking lot using crowbar tools"
        ],
        'Vandalism': [
            "Graffiti spray painted all over library walls with inappropriate messages",
            "Someone smashed multiple windows in student union with rocks and bottles"
        ],
        'Drug Activity': [
            "Suspected drug dealing behind chemistry building with money and package exchange",
            "Strong marijuana smell and drug paraphernalia found in dormitory bathroom"
        ],
        'Harassment': [
            "Student being sexually harassed by professor during private office hours meeting",
            "Racial discrimination and verbal abuse toward international students in cafeteria"
        ],
        'Safety Hazard': [
            "Broken staircase railing creating serious fall risk for all students",
            "Chemical spill in laboratory creating toxic fumes and breathing hazards"
        ],
        'Unauthorized Access': [
            "Unknown person accessed restricted laboratory using stolen faculty keycard",
            "Individual without credentials entered faculty-only building after hours"
        ],
        'Other': [
            "Power outage affecting entire campus including emergency lighting systems",
            "Food poisoning outbreak suspected from campus dining hall affecting students"
        ]
    }
    
    fake_examples = [
        "WIN $10000 NOW! Click here for free money! Limited time offer!",
        "Hot singles want to meet you! Create dating profile now!"
    ]
    
    category_results = {}
    
    for category, examples in flutter_test_cases.items():
        print(f"\n📱 {category}:")
        correct = 0
        total = len(examples)
        
        for example in examples:
            text_vec = vectorizer.transform([example])
            prediction = model.predict(text_vec)[0]
            probabilities = model.predict_proba(text_vec)[0]
            confidence = max(probabilities)
            
            is_correct = prediction == 'real'
            if is_correct:
                correct += 1
            
            status = "✅" if is_correct else "❌"
            print(f"   {status} '{example[:60]}...'")
            print(f"      Prediction: {prediction.upper()} (confidence: {confidence:.3f})")
        
        accuracy = correct / total
        category_results[category] = accuracy
        print(f"   Category Accuracy: {accuracy:.3f} ({correct}/{total})")
    
    # Test fake examples
    print(f"\n📱 Fake/Spam Examples:")
    fake_correct = 0
    for example in fake_examples:
        text_vec = vectorizer.transform([example])
        prediction = model.predict(text_vec)[0]
        probabilities = model.predict_proba(text_vec)[0]
        confidence = max(probabilities)
        
        is_correct = prediction == 'fake'
        if is_correct:
            fake_correct += 1
        
        status = "✅" if is_correct else "❌"
        print(f"   {status} '{example[:60]}...'")
        print(f"      Prediction: {prediction.upper()} (confidence: {confidence:.3f})")
    
    fake_accuracy = fake_correct / len(fake_examples)
    print(f"   Fake Detection Accuracy: {fake_accuracy:.3f} ({fake_correct}/{len(fake_examples)})")
    
    return category_results

def save_enhanced_model(model, vectorizer, results, model_name, category_results):
    """Save the enhanced model with comprehensive metadata"""
    print("💾 Saving enhanced model...")
    
    # Save model and vectorizer
    joblib.dump(model, 'safety_report_classifier_enhanced.pkl')
    joblib.dump(vectorizer, 'tfidf_vectorizer_enhanced.pkl')
    
    # Save comprehensive metadata
    metadata = {
        'model_name': model_name,
        'training_date': datetime.now().isoformat(),
        'version': '3.0_enhanced',
        'test_accuracy': results[model_name]['test_accuracy'],
        'cv_mean': results[model_name]['cv_mean'],
        'cv_std': results[model_name]['cv_std'],
        'classification_report': results[model_name]['classification_report'],
        'confusion_matrix': results[model_name]['confusion_matrix'],
        'flutter_category_accuracy': category_results,
        'notes': 'Enhanced model with comprehensive dataset matching Flutter app categories',
        'flutter_categories': [
            'Suspicious Person', 'Theft/Robbery', 'Vandalism', 'Drug Activity',
            'Harassment', 'Safety Hazard', 'Unauthorized Access', 'Other'
        ]
    }
    
    with open('model_metadata_enhanced.json', 'w') as f:
        json.dump(metadata, f, indent=2)
    
    print("✅ Enhanced model saved:")
    print("   - safety_report_classifier_enhanced.pkl")
    print("   - tfidf_vectorizer_enhanced.pkl") 
    print("   - model_metadata_enhanced.json")

def main():
    """Main enhanced training pipeline"""
    try:
        # Create comprehensive dataset
        df = create_comprehensive_dataset()
        
        # Train enhanced models
        best_model, vectorizer, results, model_name = train_enhanced_models(df)
        
        # Test with Flutter categories
        category_results = test_flutter_categories(best_model, vectorizer)
        
        # Save enhanced model
        save_enhanced_model(best_model, vectorizer, results, model_name, category_results)
        
        print("\n" + "="*70)
        print("🎉 ENHANCED TRAINING COMPLETED!")
        print("="*70)
        print(f"Best Model: {model_name}")
        print(f"CV Accuracy: {results[model_name]['cv_mean']:.3f} ± {results[model_name]['cv_std']:.3f}")
        print(f"Test Accuracy: {results[model_name]['test_accuracy']:.3f}")
        print(f"Dataset Size: {len(df)} examples")
        print(f"Features: Enhanced with Flutter app categories")
        print("✅ Model ready for deployment with Flutter app!")
        
    except Exception as e:
        print(f"❌ Enhanced training failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()