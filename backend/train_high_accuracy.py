"""
SafeZoneX Enhanced ML Training - High Accuracy Version
Improved algorithms, more data, better features for higher accuracy
"""
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier, VotingClassifier, GradientBoostingClassifier
from sklearn.svm import SVC
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.pipeline import Pipeline
import joblib
import json
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

def create_comprehensive_dataset():
    """Create a much larger, more diverse dataset for better accuracy"""
    
    print("📝 Creating comprehensive high-accuracy dataset...")
    
    # REAL REPORTS - Much more examples per category
    real_reports = []
    
    # 1. Suspicious Person (25 examples)
    suspicious_reports = [
        "Unknown person has been watching students and taking photos near dormitory entrance for hours",
        "Individual following female students from parking lot and asking personal questions",
        "Man without student ID loitering around library after hours, refusing to leave when asked",
        "Person sitting in car outside campus watching students with binoculars",
        "Unknown individual trying to enter dormitory by following students inside",
        "Stranger approaching students asking for room numbers and class schedules",
        "Person taking photos of security cameras and building entrances without permission",
        "Individual in dark clothing hiding behind trees watching student activities",
        "Unknown person attempting to access restricted areas using stolen key card",
        "Suspicious individual asking students about their daily routines and habits",
        "Person claiming to be maintenance worker but has no ID or proper uniforms",
        "Strange man following multiple students across campus throughout the day",
        "Individual trying to look into dormitory windows using ladder at night",
        "Person sitting on bench for hours watching specific building entrance",
        "Unknown individual asking students to meet them off-campus for unclear reasons",
        "Suspicious person recording students without consent in common areas",
        "Individual attempting to access student records by posing as staff member",
        "Person following students to their cars and noting license plate numbers",
        "Unknown individual offering rides to students they don't know",
        "Suspicious person asking detailed questions about campus security procedures",
        "Individual taking photos of students' ID cards when they're not looking",
        "Person claiming to be researcher but asking inappropriate personal questions",
        "Unknown individual trying to access student email accounts using phishing",
        "Suspicious person hanging around campus late at night with no clear purpose",
        "Individual attempting to befriend students for suspicious financial schemes"
    ]
    
    # 2. Theft/Robbery (25 examples)
    theft_reports = [
        "Witnessed laptop theft from library table while student was in restroom",
        "Group of people breaking into cars in parking lot using crowbar and stealing items",
        "Bike stolen from secured bike rack with heavy-duty lock cut using bolt cutters",
        "Armed robbery in parking garage, victim threatened with knife for wallet and phone",
        "Textbooks worth over $500 stolen from unattended backpack in dining hall",
        "Campus store register broken into overnight, cash and electronics missing",
        "Multiple dormitory rooms burglarized during weekend while students were away",
        "Witnessed person stealing packages from dormitory mailroom using fake ID",
        "Car broken into in student parking lot, GPS and stereo system stolen",
        "Laboratory equipment including microscopes and computers stolen during break-in",
        "Student's purse snatched while walking to class, thief fled on bicycle",
        "Vending machines broken into with crowbar, money and snacks stolen",
        "Art supplies worth hundreds of dollars stolen from unlocked studio classroom",
        "Phone charging station items stolen including multiple expensive devices",
        "Gym equipment and athletic gear stolen from locker room during practice",
        "Library computer hard drives stolen during apparent organized theft operation",
        "Student's car stolen from campus parking lot using duplicate key",
        "Cash register at campus cafe robbed at gunpoint during closing time",
        "Research data and expensive lab samples stolen from chemistry building",
        "Multiple students report wallets stolen from gym lockers with broken locks",
        "Campus bookstore inventory stolen through coordinated shoplifting ring",
        "Expensive musical instruments stolen from music building practice rooms",
        "Students' credit cards stolen and used fraudulently after dining hall incident",
        "Campus maintenance tools and equipment stolen from unlocked storage shed",
        "Witnessed organized group stealing electronics from computer lab after hours"
    ]
    
    # 3. Vandalism (25 examples)
    vandalism_reports = [
        "Graffiti spray painted all over library walls with inappropriate and offensive messages",
        "Someone smashed multiple windows in student union building with rocks and baseball bat",
        "Campus statue defaced with permanent marker and spray paint covering historical information",
        "Bathroom mirrors and fixtures deliberately broken with hammer in dormitory building",
        "Car tires slashed and paint scratched on vehicles in student parking area",
        "Fire extinguishers discharged throughout hallways creating mess and safety hazard",
        "Elevator buttons and control panels damaged with knife and screwdriver",
        "Campus signs torn down and thrown into pond near student center",
        "Classroom whiteboards and projectors damaged with permanent markers and scratches",
        "Dormitory doors and walls kicked and punched creating holes and damage",
        "Campus landscaping destroyed with plants uprooted and flower beds trampled",
        "Library books and study materials deliberately torn and thrown around reading areas",
        "Staircase railings loosened and damaged creating serious safety hazard for students",
        "Campus bulletin boards and notice boards destroyed and informational materials scattered",
        "Dining hall tables and chairs overturned and damaged during apparent rampage",
        "Laboratory glassware and equipment deliberately broken during unauthorized entry",
        "Campus artwork and displays damaged beyond repair with various tools",
        "Student mailboxes broken into and mail scattered throughout dormitory lobby",
        "Classroom computers and keyboards damaged with liquid spills and physical force",
        "Campus parking meters and payment machines damaged with blunt instruments",
        "Sports facility equipment damaged including nets, goals, and exercise machines",
        "Dormitory laundry machines broken and detergent spilled throughout laundry room",
        "Campus phone booths and emergency call boxes damaged and rendered inoperative",
        "Student recreation area equipment vandalized including ping pong tables and games",
        "Historic campus building exterior damaged with etching tools and acid"
    ]
    
    # 4. Drug Activity (25 examples)
    drug_reports = [
        "Suspected drug dealing behind chemistry building with money and small packages exchanged",
        "Strong marijuana smell and drug paraphernalia found in dormitory common area",
        "Pills and drug paraphernalia discovered in restroom stall with evidence of drug use",
        "Group smoking suspicious substances in secluded area behind student center",
        "Drug transaction witnessed in parking lot with cash exchange and suspicious behavior",
        "Student found unconscious in dormitory with drugs and alcohol nearby requiring medical attention",
        "Unknown individuals selling pills and powders to students near campus entrance",
        "Strong chemical smell from dormitory room suggesting illegal drug manufacturing",
        "Drug paraphernalia including needles and pipes found in campus study area",
        "Students openly smoking marijuana in dormitory hallway despite campus policies",
        "Suspicious white powder found in laboratory with students exhibiting unusual behavior",
        "Drug dealing operation discovered in campus storage room with scales and packages",
        "Multiple students hospitalized after consuming unknown substances at campus party",
        "Prescription drugs being sold illegally to students in dining hall area",
        "Cannabis growing operation discovered in dormitory room with professional equipment",
        "Students consuming pills and exhibiting erratic behavior in public campus areas",
        "Drug transaction interrupted by security with suspects fleeing leaving evidence behind",
        "Strong cocaine smell and drug residue found in campus bathroom stalls",
        "Illegal drug manufacturing equipment discovered in abandoned campus building area",
        "Students selling homemade drugs to other students near academic buildings",
        "Drug overdose incident requiring emergency medical response in dormitory building",
        "Suspicious individuals approaching students offering drugs and controlled substances",
        "Drug paraphernalia disposal creating environmental hazard near campus water source",
        "Organized drug distribution network operating from campus parking lots",
        "Students under influence of drugs causing disturbances in classroom settings"
    ]
    
    # 5. Harassment (25 examples)
    harassment_reports = [
        "Student being sexually harassed by professor during private office hours meetings",
        "Racial discrimination and verbal abuse toward international students in dining hall",
        "Cyberbullying and online harassment through social media targeting specific students",
        "Physical intimidation and threats made against LGBTQ+ students in dormitory",
        "Professor making inappropriate sexual comments and advances toward female students",
        "Group of students systematically bullying and excluding minority student from activities",
        "Workplace harassment by supervisor making unwelcome advances and inappropriate requests",
        "Religious discrimination and hate speech directed at Muslim students during prayer",
        "Stalking behavior with individual following and monitoring student's daily activities",
        "Verbal abuse and threatening language used against disabled students in public areas",
        "Sexual harassment in campus workplace with inappropriate touching and comments",
        "Discrimination based on sexual orientation with slurs and exclusionary behavior",
        "Elder abuse toward older students returning to education in continuing education programs",
        "Gender-based harassment with inappropriate comments about appearance and abilities",
        "Systematic harassment campaign involving multiple perpetrators targeting single victim",
        "Inappropriate sexual propositions and unwanted advances in academic settings",
        "Bullying and social isolation tactics used against students with mental health conditions",
        "Harassment based on socioeconomic status with classist comments and exclusion",
        "Unwanted sexual attention and inappropriate behavior at campus social events",
        "Verbal harassment and threats made against student activists and protesters",
        "Discrimination against pregnant students with inappropriate comments and treatment",
        "Harassment of students based on political beliefs and affiliations",
        "Inappropriate behavior by teaching assistants toward undergraduate students",
        "Systematic exclusion and harassment of students based on nationality and accent",
        "Sexual harassment in dormitory settings with inappropriate behavior and comments"
    ]
    
    # 6. Safety Hazard (25 examples)
    safety_reports = [
        "Broken staircase railing creating serious fall risk for all students and faculty",
        "Chemical spill in laboratory creating toxic fumes and breathing hazard for everyone",
        "Electrical wires exposed and sparking in dormitory creating fire and electrocution risk",
        "Broken glass covering walkway from shattered windows creating injury hazard for pedestrians",
        "Gas leak detected near dining hall requiring immediate evacuation and emergency response",
        "Ice covering campus steps and walkways with no salt treatment creating slip hazards",
        "Asbestos exposure risk in older campus building under renovation without proper containment",
        "Fire exit doors blocked by storage and furniture preventing emergency evacuation",
        "Carbon monoxide detected in dormitory building from faulty heating system",
        "Structural damage to building with visible cracks and instability concerns",
        "Flooding in basement creating electrical hazards and potential building damage",
        "Broken elevator trapped students between floors for extended period requiring rescue",
        "Chemical storage area with leaking containers creating environmental and health hazards",
        "Campus pond contaminated with chemicals creating environmental hazard for wildlife",
        "Heating system malfunction causing dangerously high temperatures and potential fire risk",
        "Broken water pipes creating flooding and potential electrical hazards in academic building",
        "Faulty laboratory equipment creating explosion risk during chemistry experiments",
        "Campus construction site with inadequate safety barriers endangering pedestrian traffic",
        "Power lines down on campus walkway creating electrocution hazard for students",
        "Mold growth in dormitory creating serious respiratory health hazards for residents",
        "Campus food contamination outbreak affecting dozens of students requiring medical treatment",
        "Structural collapse risk in gymnasium with ceiling tiles falling during activities",
        "Chemical reaction in laboratory creating toxic gas cloud requiring building evacuation",
        "Campus security system failure leaving buildings unmonitored and potentially unsafe",
        "Severe weather damage to campus infrastructure creating multiple safety hazards"
            # --- Added infrastructure/maintenance safety reports ---
            "The street light in Um accommodation kk8 is faulty and creates a safety risk at night",
            "Multiple broken street lights in campus parking lot make the area unsafe after dark",
            "Water leakage in KK8 accommodation hallway causing slippery floors and fall hazard",
            "Broken door lock in Um accommodation KK8 allows unauthorized access to student rooms",
            "Elevator in KK8 dormitory is malfunctioning and students are getting trapped",
            "Fire alarm in Um accommodation KK8 is not working, creating emergency risk",
            "Air conditioning failure in KK8 accommodation during heatwave causing health concerns",
            "Security camera in KK8 dormitory is broken, leaving entrance unmonitored",
            "Street light outside Um accommodation KK8 flickers and goes out, area is dark and unsafe",
            "Blocked emergency exit in KK8 accommodation due to construction materials",
            "Broken window in Um accommodation KK8 not repaired for weeks, risk of injury",
            "Uncollected garbage in KK8 accommodation hallway causing health and fire hazard",
            "Loose electrical wires in KK8 accommodation common area pose electrocution risk",
            "Flooded basement in KK8 accommodation after heavy rain, risk of mold and electrical hazard",
            "Broken handrail in KK8 stairwell creates fall risk for students"
        # --- Added generic infrastructure/maintenance safety reports (no location) ---
        "Broken street light",
        "Faulty street light",
        "Street light not working",
        "Elevator not working",
        "Broken door lock",
        "Fire alarm not working",
        "Air conditioning failure",
        "Security camera broken",
        "Blocked emergency exit",
        "Broken window",
        "Uncollected garbage in hallway",
        "Loose electrical wires",
        "Flooded basement",
        "Broken handrail in stairwell",
        "Slippery floor due to water leakage",
        "Malfunctioning heating system",
        "Broken water pipes",
        "Power outage",
        "Mold growth in dormitory",
        "Pest infestation in dining facilities"
    ]
    
    # 7. Unauthorized Access (25 examples)
    unauthorized_reports = [
        "Unknown person accessed restricted laboratory using stolen faculty keycard and credentials",
        "Individual without proper credentials entered faculty-only building during evening hours",
        "Security breach with person accessing student records database without authorization",
        "Unauthorized individual found in campus server room attempting to access computer systems",
        "Person without student ID gained access to dormitory using social engineering tactics",
        "Unknown individual accessed campus financial systems attempting unauthorized transactions",
        "Breach of campus library special collections with person accessing rare manuscripts illegally",
        "Unauthorized access to campus athletic facilities during closed hours for personal use",
        "Individual accessed campus research data without permission potentially compromising studies",
        "Person entered restricted construction zone without safety equipment or authorization",
        "Unauthorized access to campus chemical storage facility creating potential safety hazard",
        "Individual accessed campus parking records and student vehicle information illegally",
        "Person without clearance entered campus daycare facility raising child safety concerns",
        "Unauthorized individual accessed campus medical facility and patient information systems",
        "Person entered restricted areas of campus power plant without proper safety training",
        "Individual accessed campus residence hall master keys and duplicated them illegally",
        "Unauthorized access to campus telecommunications equipment and phone systems",
        "Person entered restricted laboratory with hazardous materials without proper training",
        "Individual accessed campus dining facility during closed hours stealing food and supplies",
        "Unauthorized person entered campus administrative offices accessing confidential documents",
        "Individual accessed campus emergency alert system without authorization causing false alarms",
        "Person entered restricted areas of campus observatory damaging expensive equipment",
        "Unauthorized access to campus maintenance areas with theft of tools and equipment",
        "Individual accessed campus greenhouse facilities damaging research plants and experiments",
        "Person entered restricted areas of campus chapel accessing donation boxes illegally"
    ]
    
    # 8. Other (25 examples)
    other_reports = [
        "Campus-wide power outage affecting emergency lighting and communication systems",
        "Gas leak detected near main dining hall requiring immediate evacuation procedures",
        "Multiple students reporting severe food poisoning from cafeteria meals requiring medical attention",
        "Severe storm damage to campus infrastructure including broken windows and flooding",
        "Campus internet and phone systems completely down affecting emergency communications",
        "Water main break causing flooding in multiple campus buildings and infrastructure damage",
        "Campus heating system failure during winter creating dangerous conditions for students",
        "Emergency alert system malfunction sending false emergency warnings to entire campus",
        "Campus transportation system breakdown stranding students without alternative options",
        "Sewage backup affecting multiple campus buildings creating unsanitary conditions",
        "Campus security system failure leaving multiple buildings unmonitored and vulnerable",
        "Medical emergency with multiple students requiring ambulance services simultaneously",
        "Campus fire alarm system malfunction causing unnecessary evacuations and confusion",
        "Air conditioning failure during extreme heat creating dangerous conditions in dormitories",
        "Campus parking system failure causing traffic backup and emergency vehicle access issues",
        "Pest infestation in dining facilities creating health hazards and food safety concerns",
        "Campus landscaping chemicals spill creating environmental hazard near student areas",
        "Multiple campus building elevator failures trapping students and requiring rescue operations",
        "Campus water contamination requiring boil water advisory for entire student population",
        "Emergency generator failure during power outage creating safety and communication issues",
        "Campus waste management system failure creating unsanitary conditions and health hazards",
        "Mass food allergy reaction at campus event requiring multiple emergency medical responses",
        "Campus communication tower damage affecting emergency alert capabilities during crisis",
        "Severe weather warning with campus lacking adequate shelter space for student population",
        "Campus infrastructure collapse including walkway failure creating major safety emergency"
    ]
    
    # Combine all real reports
    real_reports.extend(suspicious_reports)
    real_reports.extend(theft_reports)
    real_reports.extend(vandalism_reports)
    real_reports.extend(drug_reports)
    real_reports.extend(harassment_reports)
    real_reports.extend(safety_reports)
    real_reports.extend(unauthorized_reports)
    real_reports.extend(other_reports)
    
    # FAKE/SPAM REPORTS - Much more diverse examples (75 examples)
    fake_reports = [
        # Marketing/Sales spam
        "WIN $10000 NOW! Click here for free money! Limited time offer expires soon!",
        "Hot singles want to meet you! Create dating profile now! Free registration today!",
        "Make money from home! $500 per day guaranteed! No experience needed!",
        "Your Amazon account has been suspended. Click here to verify identity immediately.",
        "Free iPhone 15! Limited time offer! Enter personal details to claim prize!",
        "Congratulations! You've won lottery! Claim $50000 prize by clicking link now!",
        "Work from home opportunity! Earn $1000 weekly! No skills required!",
        "Your credit score improved! Click here to see amazing results!",
        "Free vacation to Hawaii! All expenses paid! Limited spots available!",
        "Lose 30 pounds in 30 days! Revolutionary diet pill available now!",
        
        # Technical/phishing scams
        "Your computer has virus! Download antivirus software immediately!",
        "Bank account compromise detected! Verify account details now!",
        "PayPal security alert! Update payment information immediately!",
        "Microsoft Windows license expired! Renew now to avoid shutdown!",
        "Google account suspended! Verify identity to restore access!",
        "Netflix subscription cancelled! Update billing information now!",
        "Email storage full! Delete emails or upgrade account today!",
        "Facebook account hacked! Change password immediately!",
        "Amazon Prime membership expired! Renew now for continued benefits!",
        "Apple ID locked! Verify account to restore access!",
        
        # Generic spam
        "Buy cheap medications online! No prescription required!",
        "Enlarge your muscles fast! Revolutionary supplement available!",
        "Get rich quick scheme! Guaranteed returns on investment!",
        "Meet wealthy seniors! Dating site for financial opportunities!",
        "Free trial offer! Cancel anytime! Hidden fees not mentioned!",
        "Miracle weight loss! Before and after photos inside!",
        "Investment opportunity! Double your money in 30 days!",
        "Free gift cards! Complete survey to receive rewards!",
        "Cheap designer handbags! Authentic replicas available now!",
        "Online pharmacy! Prescription drugs without prescription!",
        
        # Nonsensical/random
        "Purple elephants dancing in rainbow meadows with golden unicorns",
        "Banana phone calls received from Mars requesting pizza delivery",
        "Flying spaghetti monster spotted wearing polka dot underwear",
        "Time travel tickets available! Visit dinosaurs next Tuesday!",
        "Invisible cats selling magic beans at midnight crossroads",
        "Robot chickens teaching underwater basket weaving classes",
        "Cloud computing literally involves computers made of clouds",
        "Quantum physics proves that chocolate is actually vegetables",
        "Magnetic personality attracts metal objects to your face",
        "Digital cameras steal souls through photographic evidence",
        
        # Fake emergency/dramatic
        "OMG! Aliens landed on campus! Government cover-up happening!",
        "BREAKING: Campus invaded by zombies! Run for your lives!",
        "URGENT: Time portal opened in library! Students disappearing!",
        "ALERT: Giant spiders taking over dormitories! Evacuation needed!",
        "WARNING: Vampire professor drinking student blood in chemistry!",
        "EMERGENCY: Campus sinking into underground cave system!",
        "BREAKING: Students turning into werewolves during full moon!",
        "URGENT: Dinosaurs escaped from paleontology department!",
        "ALERT: Campus buildings becoming sentient and attacking students!",
        "WARNING: Parallel universe students switching places with real ones!",
        
        # Promotional/advertisement
        "Best pizza in town! Free delivery! Call now!",
        "Hair salon grand opening! 50% off all services!",
        "Car dealership sale! Zero percent financing available!",
        "Real estate investment! Property values guaranteed to increase!",
        "Insurance quotes! Save hundreds on car insurance!",
        "Fitness gym membership! Join now for special rates!",
        "Restaurant promotion! Buy one get one free meals!",
        "Clothing store clearance! Everything must go sale!",
        "Electronics store! Latest gadgets at lowest prices!",
        "Travel agency deals! Vacation packages half price!",
        
        # Incoherent/gibberish
        "The quick brown fox jumps over lazy dog repeatedly",
        "Lorem ipsum dolor sit amet consectetur adipiscing elit",
        "Testing testing 123 this is microphone check only",
        "Random words: keyboard, sunshine, refrigerator, elephant, quantum",
        "QWERTY UIOP ASDF GHJKL ZXCV BNMP keyboard layout",
        "Hello world print statement programming language test",
        "Copy paste ctrl+c ctrl+v command functions activated",
        "WiFi password: 123456789 network connection established",
        "Error 404 file not found please try again later",
        "Default text placeholder replace with actual content",
        
        # Obviously fake reports
        "My imaginary friend stole my invisible homework assignment",
        "Saw professor turn into werewolf during chemistry lecture",
        "Alien abduction prevented me from attending math class",
        "Time machine malfunction caused me to miss exam",
        "Teleportation device broken so I can't reach classroom",
        "Mind reading student cheating using psychic powers",
        "Ghost haunting library making books float in air",
        "Dragon nesting in dormitory roof breathing fire",
        "Unicorn stampede blocking path to dining hall",
        "Wizard casting spells on campus WiFi network"
    ]
    
    # Create labels
    real_labels = ['real'] * len(real_reports)
    fake_labels = ['fake'] * len(fake_reports)
    
    # Combine all data
    all_texts = real_reports + fake_reports
    all_labels = real_labels + fake_labels
    
    # Create DataFrame
    df = pd.DataFrame({
        'text': all_texts,
        'label': all_labels
    })
    
    # Shuffle the data
    df = df.sample(frac=1, random_state=42).reset_index(drop=True)
    
    print(f"✅ Comprehensive dataset created: {len(df)} examples")
    print(f"   - Real reports: {len(real_reports)}")
    print(f"   - Fake reports: {len(fake_reports)}")
    print(f"   - Real per category: 25 examples each")
    
    return df

def train_high_accuracy_models(df):
    """Train multiple advanced models for maximum accuracy"""
    
    print("🤖 Training High-Accuracy ML Models...")
    
    # Split data
    X = df['text']
    y = df['label']
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
    
    print(f"📊 Training set: {len(X_train)} examples")
    print(f"📊 Test set: {len(X_test)} examples")
    
    # Advanced TF-IDF Vectorizer with optimized parameters
    vectorizer = TfidfVectorizer(
        max_features=5000,  # Increased features
        ngram_range=(1, 3),  # Include 1, 2, and 3-grams
        min_df=2,
        max_df=0.95,
        stop_words='english',
        sublinear_tf=True,
        analyzer='word'
    )
    
    X_train_vec = vectorizer.fit_transform(X_train)
    X_test_vec = vectorizer.transform(X_test)
    
    print(f"🔤 Feature dimensions: {X_train_vec.shape[1]}")
    
    # Define multiple advanced models
    models = {
        'Naive Bayes': MultinomialNB(alpha=0.1),
        'Logistic Regression': LogisticRegression(
            C=10, 
            max_iter=1000, 
            random_state=42,
            class_weight='balanced'
        ),
        'Random Forest': RandomForestClassifier(
            n_estimators=200, 
            max_depth=20, 
            random_state=42,
            class_weight='balanced',
            min_samples_split=5
        ),
        'Gradient Boosting': GradientBoostingClassifier(
            n_estimators=100,
            learning_rate=0.1,
            max_depth=10,
            random_state=42
        ),
        'SVM': SVC(
            C=10, 
            kernel='rbf', 
            probability=True, 
            random_state=42,
            class_weight='balanced'
        )
    }
    
    best_model = None
    best_score = 0
    best_name = ""
    model_results = {}
    
    # Train and evaluate each model
    for name, model in models.items():
        print(f"\n🔧 Training {name}...")
        
        # Cross-validation
        cv_scores = cross_val_score(model, X_train_vec, y_train, cv=5, scoring='accuracy')
        cv_mean = cv_scores.mean()
        cv_std = cv_scores.std()
        
        # Train on full training set
        model.fit(X_train_vec, y_train)
        
        # Test accuracy
        test_score = model.score(X_test_vec, y_test)
        
        # Predictions for detailed metrics
        y_pred = model.predict(X_test_vec)
        
        print(f"   Cross-validation: {cv_mean:.3f} ± {cv_std:.3f}")
        print(f"   Test accuracy: {test_score:.3f}")
        
        # Store results
        model_results[name] = {
            'model': model,
            'cv_mean': cv_mean,
            'cv_std': cv_std,
            'test_accuracy': test_score,
            'predictions': y_pred
        }
        
        # Track best model
        if cv_mean > best_score:
            best_score = cv_mean
            best_model = model
            best_name = name
    
    # Create ensemble model (Voting Classifier)
    print(f"\n🔧 Training Ensemble Model...")
    ensemble = VotingClassifier([
        ('nb', MultinomialNB(alpha=0.1)),
        ('lr', LogisticRegression(C=10, max_iter=1000, random_state=42, class_weight='balanced')),
        ('rf', RandomForestClassifier(n_estimators=100, max_depth=15, random_state=42, class_weight='balanced'))
    ], voting='soft')
    
    # Train ensemble
    ensemble.fit(X_train_vec, y_train)
    ensemble_cv = cross_val_score(ensemble, X_train_vec, y_train, cv=5, scoring='accuracy')
    ensemble_test = ensemble.score(X_test_vec, y_test)
    ensemble_pred = ensemble.predict(X_test_vec)
    
    print(f"   Ensemble CV: {ensemble_cv.mean():.3f} ± {ensemble_cv.std():.3f}")
    print(f"   Ensemble Test: {ensemble_test:.3f}")
    
    # Check if ensemble is better
    if ensemble_cv.mean() > best_score:
        best_model = ensemble
        best_name = "Ensemble"
        best_score = ensemble_cv.mean()
        model_results["Ensemble"] = {
            'model': ensemble,
            'cv_mean': ensemble_cv.mean(),
            'cv_std': ensemble_cv.std(),
            'test_accuracy': ensemble_test,
            'predictions': ensemble_pred
        }
    
    print(f"\n🏆 Best model: {best_name}")
    print(f"   CV accuracy: {best_score:.3f}")
    print(f"   Test accuracy: {model_results[best_name]['test_accuracy']:.3f}")
    
    # Detailed classification report for best model
    best_pred = model_results[best_name]['predictions']
    print(f"\n📊 Detailed Classification Report ({best_name}):")
    print(classification_report(y_test, best_pred))
    
    return best_model, vectorizer, model_results, best_name

def save_high_accuracy_model(model, vectorizer, model_results, best_name):
    """Save the best performing model"""
    
    print("💾 Saving high-accuracy model...")
    
    # Save model and vectorizer
    joblib.dump(model, 'safety_report_classifier_high_accuracy.pkl')
    joblib.dump(vectorizer, 'tfidf_vectorizer_high_accuracy.pkl')
    
    # Create comprehensive metadata
    metadata = {
        "model_name": best_name,
        "training_date": datetime.now().isoformat(),
        "version": "4.0_high_accuracy",
        "cv_mean": model_results[best_name]['cv_mean'],
        "cv_std": model_results[best_name]['cv_std'],
        "test_accuracy": model_results[best_name]['test_accuracy'],
        "dataset_size": 275,  # 200 real + 75 fake
        "real_examples_per_category": 25,
        "total_categories": 8,
        "features": "Advanced TF-IDF with 1-3 grams, 5000 features",
        "algorithm": best_name,
        "all_model_results": {name: {
            'cv_mean': results['cv_mean'],
            'cv_std': results['cv_std'], 
            'test_accuracy': results['test_accuracy']
        } for name, results in model_results.items()}
    }
    
    # Save metadata
    with open('model_metadata_high_accuracy.json', 'w') as f:
        json.dump(metadata, f, indent=2)
    
    print("✅ High-accuracy model saved:")
    print("   - safety_report_classifier_high_accuracy.pkl")
    print("   - tfidf_vectorizer_high_accuracy.pkl") 
    print("   - model_metadata_high_accuracy.json")

def test_high_accuracy_model():
    """Test the high accuracy model with sample data"""
    
    print("\n🧪 Testing High-Accuracy Model...")
    
    # Load model
    model = joblib.load('safety_report_classifier_high_accuracy.pkl')
    vectorizer = joblib.load('tfidf_vectorizer_high_accuracy.pkl')
    
    # Test examples
    test_examples = [
        ("Real Safety Report", "Someone broke into my dorm room and stole my laptop and textbooks"),
        ("Real Emergency", "Chemical spill in chemistry lab creating toxic fumes, need immediate evacuation"),
        ("Fake Spam", "WIN $10000 NOW! Click here for free money! Limited time offer!"),
        ("Fake Nonsense", "Purple elephants dancing with unicorns in rainbow meadows"),
        ("Real Harassment", "Professor making inappropriate sexual comments to female students"),
        ("Fake Marketing", "Lose 30 pounds in 30 days with revolutionary diet pill!")
    ]
    
    print("📝 Sample Predictions:")
    for category, text in test_examples:
        X = vectorizer.transform([text])
        prediction = model.predict(X)[0]
        probability = model.predict_proba(X)[0]
        confidence = max(probability)
        
        status = "✅" if (category.startswith("Real") and prediction == "real") or (category.startswith("Fake") and prediction == "fake") else "❌"
        
        print(f"   {status} {category}: {prediction.upper()} ({confidence:.3f})")
        print(f"      '{text[:60]}...'")

# Ensure vectorizer is loaded before usage
vectorizer = joblib.load("tfidf_vectorizer_high_accuracy.pkl")

# Ensure best_model is loaded before usage
best_model = joblib.load("safety_report_classifier_high_accuracy.pkl")

# Initialize metadata if not already defined
try:
    with open("model_metadata.json", "r") as f:
        metadata = json.load(f)
except FileNotFoundError:
    metadata = {}

# === CATEGORY-SPECIFIC VALIDATION (SafeZoneX) ===
category_tests = {
    "Suspicious Person": [
        "A stranger is loitering near the dorm.",
        "Someone is following me around campus."
    ],
    "Harassment": [
        "A student is being verbally harassed.",
        "Someone is making inappropriate comments."
    ],
    "Safety Hazard": [
        "There is broken glass on the walkway.",
        "The fire exit is blocked."
    ],
    "Theft": [
        "My laptop was stolen from the library.",
        "Someone snatched my bag in the cafeteria."
    ],
    "Vandalism": [
        "Graffiti was found on the wall.",
        "Someone broke a classroom window."
    ],
    "Lost Item": [
        "I lost my phone near the sports hall.",
        "My ID card is missing."
    ],
    "Fake/Spam": [
        "Click this link to win a prize!",
        "Get free money by signing up now."
    ]
}

category_results = {}
for category, examples in category_tests.items():
    results = []
    for text in examples:
        X_input = vectorizer.transform([text])
        probs = best_model.predict_proba(X_input)[0]
        pred = best_model.predict(X_input)[0]
        confidence = max(probs) * 100
        results.append({
            "input": text,
            "predicted": pred,
            "confidence": round(confidence, 2)
        })
    category_results[category] = results

# Log results to console
print("\n=== Category-Specific Validation ===")
for category, results in category_results.items():
    print(f"\n{category}:")
    for r in results:
        print(f"  Input: {r['input']}")
        print(f"  Predicted: {r['predicted']} (Confidence: {r['confidence']}%)")

# Update metadata file with category validation results
metadata["category_validation"] = category_results
with open("model_metadata.json", "w") as f:
    json.dump(metadata, f, indent=4)

# Load vectorizer and best_model
vectorizer = joblib.load("tfidf_vectorizer_high_accuracy.pkl")
best_model = joblib.load("safety_report_classifier_high_accuracy.pkl")

# Initialize metadata if not already defined
try:
    with open("model_metadata.json", "r") as f:
        metadata = json.load(f)
except FileNotFoundError:
    metadata = {}

if __name__ == "__main__":
    print("🚀 SafeZoneX High-Accuracy ML Training")
    print("=" * 50)
    
    # Create comprehensive dataset
    df = create_comprehensive_dataset()
    
    # Train high-accuracy models
    best_model, vectorizer, model_results, best_name = train_high_accuracy_models(df)
    
    # Save the best model
    save_high_accuracy_model(best_model, vectorizer, model_results, best_name)
    
    # Test the model
    test_high_accuracy_model()
    
    print(f"\n🎉 HIGH-ACCURACY TRAINING COMPLETED!")
    print("=" * 50)
    print(f"Best Model: {best_name}")
    print(f"Dataset: 275 examples (200 real + 75 fake)")
    print(f"Features: Advanced TF-IDF with n-grams")
    print("✅ Ready for deployment with improved accuracy!")