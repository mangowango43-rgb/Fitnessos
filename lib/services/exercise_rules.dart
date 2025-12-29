import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class ExerciseRule {
  final String id, name, cueGood, cueBad, cameraPosition;
  final PoseLandmarkType jointA, jointB, jointC;
  final double extendedAngle, contractedAngle, goodFormMin, goodFormMax;
  final bool countOnContraction;

  const ExerciseRule({
    required this.id, required this.name,
    required this.jointA, required this.jointB, required this.jointC,
    required this.extendedAngle, required this.contractedAngle,
    this.countOnContraction = true,
    required this.goodFormMin, required this.goodFormMax,
    this.cueGood = "Good!", this.cueBad = "Check form!",
    this.cameraPosition = 'SIDE',
  });
}

// Landmark shortcuts
const _sh = PoseLandmarkType.rightShoulder;
const _el = PoseLandmarkType.rightElbow;
const _wr = PoseLandmarkType.rightWrist;
const _hp = PoseLandmarkType.rightHip;
const _kn = PoseLandmarkType.rightKnee;
const _ak = PoseLandmarkType.rightAnkle;
const _lsh = PoseLandmarkType.leftShoulder;
const _lkn = PoseLandmarkType.leftKnee;
const _ler = PoseLandmarkType.rightEar;
const _ft = PoseLandmarkType.rightFootIndex;
const _lel = PoseLandmarkType.leftElbow;
const _lhp = PoseLandmarkType.leftHip;

class ExerciseRules {
  
  // ==================== CHEST ====================
  static const benchPress = ExerciseRule(id: 'bench_press', name: 'Bench Press', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 75, goodFormMin: 70, goodFormMax: 95, cueGood: "Perfect!", cueBad: "Touch chest!");
  static const inclinePress = ExerciseRule(id: 'incline_press', name: 'Incline Press', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 160, contractedAngle: 80, goodFormMin: 75, goodFormMax: 90, cueGood: "Great!", cueBad: "Full range!");
  static const declinePress = ExerciseRule(id: 'decline_press', name: 'Decline Press', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 170, contractedAngle: 85, goodFormMin: 80, goodFormMax: 95, cueGood: "Strong!", cueBad: "Lower!");
  static const chestFlys = ExerciseRule(id: 'chest_flys', name: 'Chest Flys', jointA: _wr, jointB: _sh, jointC: _lsh, extendedAngle: 160, contractedAngle: 45, goodFormMin: 40, goodFormMax: 170, cueGood: "Stretch!", cueBad: "Slight bend!", cameraPosition: 'FRONT');
  static const pushUps = ExerciseRule(id: 'push_ups', name: 'Push-ups', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 80, goodFormMin: 70, goodFormMax: 90, cueGood: "Great depth!", cueBad: "Go lower!");
  static const widePushUps = ExerciseRule(id: 'wide_pushups', name: 'Wide Push-ups', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 85, goodFormMin: 75, goodFormMax: 95, cueGood: "Wide!", cueBad: "Chest down!");
  static const dipsChest = ExerciseRule(id: 'dips_chest', name: 'Dips', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 160, contractedAngle: 85, goodFormMin: 80, goodFormMax: 95, cueGood: "Nice dip!", cueBad: "Get to 90!");
  static const cableCrossovers = ExerciseRule(id: 'cable_crossovers', name: 'Cable Crossovers', jointA: _wr, jointB: _sh, jointC: _lsh, extendedAngle: 150, contractedAngle: 40, goodFormMin: 35, goodFormMax: 160, cueGood: "Squeeze!", cueBad: "Wide!", cameraPosition: 'FRONT');
  static const landminePress = ExerciseRule(id: 'landmine_press', name: 'Landmine Press', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 90, countOnContraction: false, goodFormMin: 155, goodFormMax: 175, cueGood: "Lock!", cueBad: "Press high!");
  static const machineFly = ExerciseRule(id: 'machine_chest_fly', name: 'Machine Chest Fly', jointA: _wr, jointB: _sh, jointC: _lsh, extendedAngle: 160, contractedAngle: 45, goodFormMin: 40, goodFormMax: 170, cueGood: "Squeeze!", cueBad: "Control!", cameraPosition: 'FRONT');
  static const dumbbellFlyes = ExerciseRule(id: 'dumbbell_flyes', name: 'Dumbbell Flyes', jointA: _wr, jointB: _sh, jointC: _lsh, extendedAngle: 160, contractedAngle: 45, goodFormMin: 40, goodFormMax: 170, cueGood: "Stretch!", cueBad: "Slight bend!", cameraPosition: 'FRONT');

  // ==================== BACK ====================
  static const deadlift = ExerciseRule(id: 'deadlift', name: 'Deadlift', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 175, contractedAngle: 75, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Lockout!", cueBad: "Hips forward!");
  static const sumoDeadlift = ExerciseRule(id: 'sumo_deadlift', name: 'Sumo Deadlift', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 175, contractedAngle: 80, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Wide stance!", cueBad: "Hips through!");
  static const bentOverRows = ExerciseRule(id: 'bent_over_rows', name: 'Bent-Over Rows', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 170, contractedAngle: 85, goodFormMin: 80, goodFormMax: 95, cueGood: "Nice pull!", cueBad: "Squeeze lats!");
  static const pullUps = ExerciseRule(id: 'pull_ups', name: 'Pull-ups', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 170, contractedAngle: 60, goodFormMin: 45, goodFormMax: 80, cueGood: "Chin over!", cueBad: "Full stretch!", cameraPosition: 'FRONT');
  static const latPulldowns = ExerciseRule(id: 'lat_pulldowns', name: 'Lat Pulldowns', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 170, contractedAngle: 65, goodFormMin: 55, goodFormMax: 85, cueGood: "Lats!", cueBad: "Pull to chest!", cameraPosition: 'FRONT');
  static const cableRows = ExerciseRule(id: 'cable_rows', name: 'Cable Rows', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 170, contractedAngle: 90, goodFormMin: 85, goodFormMax: 100, cueGood: "Perfect!", cueBad: "Full row!");
  static const tBarRows = ExerciseRule(id: 't_bar_rows', name: 'T-Bar Rows', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 85, goodFormMin: 80, goodFormMax: 95, cueGood: "Nice!", cueBad: "Squeeze!");
  static const facePulls = ExerciseRule(id: 'face_pulls', name: 'Face Pulls', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 170, contractedAngle: 80, goodFormMin: 70, goodFormMax: 95, cueGood: "Great pull!", cueBad: "To ears!", cameraPosition: 'FRONT');
  static const reverseFlys = ExerciseRule(id: 'reverse_flys', name: 'Reverse Flys', jointA: _wr, jointB: _sh, jointC: _lsh, extendedAngle: 60, contractedAngle: 155, countOnContraction: false, goodFormMin: 150, goodFormMax: 175, cueGood: "Back!", cueBad: "Arms wide!", cameraPosition: 'FRONT');
  static const shrugs = ExerciseRule(id: 'shrugs', name: 'Shrugs', jointA: _hp, jointB: _sh, jointC: _ler, extendedAngle: 160, contractedAngle: 135, goodFormMin: 130, goodFormMax: 145, cueGood: "High!", cueBad: "Full shrug!", cameraPosition: 'FRONT');
  static const renegadeRows = ExerciseRule(id: 'renegade_rows', name: 'Renegade Rows', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 170, contractedAngle: 85, goodFormMin: 80, goodFormMax: 95, cueGood: "Stable!", cueBad: "Pull high!");
  static const singleArmDbRow = ExerciseRule(id: 'single_arm_db_row', name: 'Single Arm DB Row', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 170, contractedAngle: 85, goodFormMin: 80, goodFormMax: 95, cueGood: "Pull!", cueBad: "Elbow high!");

  // ==================== SHOULDERS ====================
  static const overheadPress = ExerciseRule(id: 'overhead_press', name: 'Overhead Press', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 80, contractedAngle: 165, countOnContraction: false, goodFormMin: 160, goodFormMax: 175, cueGood: "Sky high!", cueBad: "Lock out!", cameraPosition: 'FRONT');
  static const arnoldPress = ExerciseRule(id: 'arnold_press', name: 'Arnold Press', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 75, contractedAngle: 160, countOnContraction: false, goodFormMin: 155, goodFormMax: 175, cueGood: "Twist!", cueBad: "Full reach!", cameraPosition: 'FRONT');
  static const lateralRaises = ExerciseRule(id: 'lateral_raises', name: 'Lateral Raises', jointA: _hp, jointB: _sh, jointC: _wr, extendedAngle: 25, contractedAngle: 85, goodFormMin: 80, goodFormMax: 100, cueGood: "Perfect!", cueBad: "To shoulders!", cameraPosition: 'FRONT');
  static const frontRaises = ExerciseRule(id: 'front_raises', name: 'Front Raises', jointA: _hp, jointB: _sh, jointC: _wr, extendedAngle: 20, contractedAngle: 90, goodFormMin: 85, goodFormMax: 110, cueGood: "Strong!", cueBad: "Arm parallel!");
  static const rearDeltFlys = ExerciseRule(id: 'rear_delt_flys', name: 'Rear Delt Flys', jointA: _wr, jointB: _sh, jointC: _lsh, extendedAngle: 45, contractedAngle: 160, countOnContraction: false, goodFormMin: 150, goodFormMax: 180, cueGood: "Wide!", cueBad: "Full spread!", cameraPosition: 'FRONT');
  static const uprightRows = ExerciseRule(id: 'upright_rows', name: 'Upright Rows', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 60, goodFormMin: 45, goodFormMax: 80, cueGood: "High elbows!", cueBad: "Pull higher!", cameraPosition: 'FRONT');
  static const pikePushUps = ExerciseRule(id: 'pike_push_ups', name: 'Pike Push-ups', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 85, goodFormMin: 75, goodFormMax: 95, cueGood: "Deep pike!", cueBad: "Go lower!");
  static const plankShoulderTaps = ExerciseRule(id: 'plank_shoulder_taps', name: 'Plank Shoulder Taps', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 175, contractedAngle: 175, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Stable!", cueBad: "Don't rock!");
  static const seatedDbPress = ExerciseRule(id: 'seated_db_press', name: 'Seated DB Press', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 80, contractedAngle: 165, countOnContraction: false, goodFormMin: 160, goodFormMax: 175, cueGood: "Press!", cueBad: "Full extension!", cameraPosition: 'FRONT');
  static const cableLateralRaise = ExerciseRule(id: 'cable_lateral_raise', name: 'Cable Lateral Raise', jointA: _hp, jointB: _sh, jointC: _wr, extendedAngle: 25, contractedAngle: 85, goodFormMin: 80, goodFormMax: 100, cueGood: "Perfect!", cueBad: "To shoulders!", cameraPosition: 'FRONT');

  // ==================== LEGS ====================
  static const squats = ExerciseRule(id: 'squats', name: 'Squats', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 175, contractedAngle: 85, goodFormMin: 70, goodFormMax: 100, cueGood: "Depth!", cueBad: "Hit parallel!");
  static const sumoSquat = ExerciseRule(id: 'sumo_squat', name: 'Sumo Squat', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 175, contractedAngle: 90, goodFormMin: 75, goodFormMax: 105, cueGood: "Wide!", cueBad: "Deeper!", cameraPosition: 'FRONT');
  static const romanianDeadlift = ExerciseRule(id: 'romanian_deadlift', name: 'Romanian Deadlift', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 175, contractedAngle: 95, goodFormMin: 85, goodFormMax: 110, cueGood: "Hamstrings!", cueBad: "Flat back!");
  static const lunges = ExerciseRule(id: 'lunges', name: 'Lunges', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 170, contractedAngle: 95, goodFormMin: 85, goodFormMax: 105, cueGood: "Great step!", cueBad: "Deep lunge!");
  static const bulgarianSplitSquat = ExerciseRule(id: 'bulgarian_split_squat', name: 'Bulgarian Split Squat', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 165, contractedAngle: 90, goodFormMin: 80, goodFormMax: 100, cueGood: "Balance!", cueBad: "Go deeper!");
  static const legPress = ExerciseRule(id: 'leg_press', name: 'Leg Press', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 160, contractedAngle: 80, goodFormMin: 70, goodFormMax: 95, cueGood: "Push!", cueBad: "Deep press!");
  static const legExtensions = ExerciseRule(id: 'leg_extensions', name: 'Leg Extensions', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 95, contractedAngle: 165, countOnContraction: false, goodFormMin: 160, goodFormMax: 175, cueGood: "Lock!", cueBad: "Full extension!");
  static const legCurls = ExerciseRule(id: 'leg_curls', name: 'Leg Curls', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 170, contractedAngle: 85, goodFormMin: 75, goodFormMax: 95, cueGood: "Squeeze!", cueBad: "Heels to glutes!");
  static const calfRaises = ExerciseRule(id: 'calf_raises', name: 'Calf Raises', jointA: _kn, jointB: _ak, jointC: _ft, extendedAngle: 120, contractedAngle: 160, countOnContraction: false, goodFormMin: 155, goodFormMax: 175, cueGood: "Toes up!", cueBad: "Push high!");
  static const stepUps = ExerciseRule(id: 'step_ups', name: 'Step-ups', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 175, contractedAngle: 100, countOnContraction: false, goodFormMin: 170, goodFormMax: 180, cueGood: "Step tall!", cueBad: "Full step!");
  static const gobletSquats = ExerciseRule(id: 'goblet_squats', name: 'Goblet Squats', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 175, contractedAngle: 80, goodFormMin: 70, goodFormMax: 95, cueGood: "Perfect!", cueBad: "Elbows to knees!");
  static const wallSits = ExerciseRule(id: 'wall_sits', name: 'Wall Sits', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 90, contractedAngle: 90, countOnContraction: false, goodFormMin: 85, goodFormMax: 95, cueGood: "Hold it!", cueBad: "Keep 90!");
  static const jumpSquats = ExerciseRule(id: 'jump_squats', name: 'Jump Squats', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 175, contractedAngle: 100, countOnContraction: false, goodFormMin: 160, goodFormMax: 180, cueGood: "Explosive!", cueBad: "Jump high!");
  static const hipThrust = ExerciseRule(id: 'hip_thrust', name: 'Hip Thrust', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 100, contractedAngle: 175, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Squeeze!", cueBad: "Hips high!");
  static const singleLegGluteBridge = ExerciseRule(id: 'single_leg_glute_bridge', name: 'Single Leg Glute Bridge', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 120, contractedAngle: 175, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "One leg!", cueBad: "Hips level!");
  static const kettlebellSwings = ExerciseRule(id: 'kettlebell_swings', name: 'Kettlebell Swings', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 175, contractedAngle: 90, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Snap hips!", cueBad: "Drive through!");
  static const cablePullthrough = ExerciseRule(id: 'cable_pullthrough', name: 'Cable Pull-Through', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 175, contractedAngle: 90, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Squeeze!", cueBad: "Hips forward!");
  static const cableKickback = ExerciseRule(id: 'cable_kickback', name: 'Cable Kickback', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 170, contractedAngle: 140, goodFormMin: 130, goodFormMax: 155, cueGood: "Kick back!", cueBad: "Extend leg!");
  static const gluteKickbackMachine = ExerciseRule(id: 'glute_kickback', name: 'Glute Kickback Machine', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 170, contractedAngle: 140, goodFormMin: 130, goodFormMax: 155, cueGood: "Squeeze!", cueBad: "Full extension!");
  static const walkingLunges = ExerciseRule(id: 'walking_lunges', name: 'Walking Lunges', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 170, contractedAngle: 95, goodFormMin: 85, goodFormMax: 105, cueGood: "Keep moving!", cueBad: "Deep lunge!");
  static const frontSquat = ExerciseRule(id: 'front_squat', name: 'Front Squat', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 175, contractedAngle: 85, goodFormMin: 70, goodFormMax: 100, cueGood: "Upright!", cueBad: "Elbows up!");
  static const legPressHigh = ExerciseRule(id: 'leg_press_high', name: 'Leg Press (High)', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 160, contractedAngle: 80, goodFormMin: 70, goodFormMax: 95, cueGood: "Glutes!", cueBad: "Deep!");
  static const standingCalfRaise = ExerciseRule(id: 'standing_calf_raise', name: 'Standing Calf Raise', jointA: _kn, jointB: _ak, jointC: _ft, extendedAngle: 120, contractedAngle: 160, countOnContraction: false, goodFormMin: 155, goodFormMax: 175, cueGood: "Toes up!", cueBad: "Full range!");

  // ==================== ARMS ====================
  static const bicepCurls = ExerciseRule(id: 'bicep_curls', name: 'Bicep Curls', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 40, goodFormMin: 30, goodFormMax: 60, cueGood: "Full curl!", cueBad: "No swinging!");
  static const hammerCurls = ExerciseRule(id: 'hammer_curls', name: 'Hammer Curls', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 160, contractedAngle: 45, goodFormMin: 35, goodFormMax: 65, cueGood: "Nice grip!", cueBad: "Squeeze!");
  static const preacherCurls = ExerciseRule(id: 'preacher_curls', name: 'Preacher Curls', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 155, contractedAngle: 50, goodFormMin: 40, goodFormMax: 70, cueGood: "Clean!", cueBad: "Stretch out!");
  static const tricepExtensions = ExerciseRule(id: 'tricep_extensions', name: 'Tricep Extensions', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 70, contractedAngle: 165, countOnContraction: false, goodFormMin: 160, goodFormMax: 175, cueGood: "Strong!", cueBad: "Full extend!");
  static const skullCrushers = ExerciseRule(id: 'skull_crushers', name: 'Skull Crushers', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 75, goodFormMin: 65, goodFormMax: 90, cueGood: "Perfect!", cueBad: "To forehead!");
  static const overheadTricepExtension = ExerciseRule(id: 'overhead_tricep_extension', name: 'Overhead Tricep', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 60, contractedAngle: 160, countOnContraction: false, goodFormMin: 155, goodFormMax: 175, cueGood: "Reach high!", cueBad: "Lock out!");
  static const closeGripPushUps = ExerciseRule(id: 'close_grip_push_ups', name: 'Close-grip Push-ups', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 85, goodFormMin: 75, goodFormMax: 100, cueGood: "Triceps!", cueBad: "Deep push!");
  static const concentrationCurls = ExerciseRule(id: 'concentration_curls', name: 'Concentration Curls', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 150, contractedAngle: 50, goodFormMin: 40, goodFormMax: 65, cueGood: "Focus!", cueBad: "Full squeeze!");
  static const cableCurls = ExerciseRule(id: 'cable_curls', name: 'Cable Curls', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 45, goodFormMin: 35, goodFormMax: 60, cueGood: "Tension!", cueBad: "Full curl!");
  static const diamondPushUps = ExerciseRule(id: 'diamond_push_ups', name: 'Diamond Push-ups', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 160, contractedAngle: 90, goodFormMin: 80, goodFormMax: 100, cueGood: "Diamond!", cueBad: "Deep push!");
  static const tricepPushdown = ExerciseRule(id: 'tricep_pushdown', name: 'Tricep Pushdown', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 85, contractedAngle: 165, countOnContraction: false, goodFormMin: 160, goodFormMax: 175, cueGood: "Push!", cueBad: "Full extension!");
  static const tricepDips = ExerciseRule(id: 'tricep_dips', name: 'Tricep Dips', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 160, contractedAngle: 85, goodFormMin: 80, goodFormMax: 95, cueGood: "Strong!", cueBad: "Get to 90!");
  static const tricepDipsChair = ExerciseRule(id: 'tricep_dips_chair', name: 'Tricep Dips (Chair)', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 160, contractedAngle: 85, goodFormMin: 80, goodFormMax: 95, cueGood: "Strong!", cueBad: "Get to 90!");
  static const barbellCurl = ExerciseRule(id: 'barbell_curl', name: 'Barbell Curl', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 40, goodFormMin: 30, goodFormMax: 60, cueGood: "Squeeze!", cueBad: "No swinging!");
  static const closeGripBench = ExerciseRule(id: 'close_grip_bench', name: 'Close Grip Bench', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 75, goodFormMin: 70, goodFormMax: 95, cueGood: "Triceps!", cueBad: "Elbows in!");

  // ==================== CORE ====================
  static const sitUps = ExerciseRule(id: 'sit_ups', name: 'Sit-ups', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 160, contractedAngle: 45, goodFormMin: 35, goodFormMax: 55, cueGood: "Core strong!", cueBad: "All the way!");
  static const crunches = ExerciseRule(id: 'crunches', name: 'Crunches', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 165, contractedAngle: 75, goodFormMin: 65, goodFormMax: 85, cueGood: "Nice crunch!", cueBad: "Squeeze abs!");
  static const plank = ExerciseRule(id: 'plank', name: 'Plank', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 175, contractedAngle: 175, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Flat back!", cueBad: "Don't sag!");
  static const sidePlank = ExerciseRule(id: 'side_plank', name: 'Side Plank', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 180, contractedAngle: 180, countOnContraction: false, goodFormMin: 175, goodFormMax: 185, cueGood: "Hip up!", cueBad: "Stay straight!", cameraPosition: 'FRONT');
  static const legRaises = ExerciseRule(id: 'leg_raises', name: 'Leg Raises', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 175, contractedAngle: 95, goodFormMin: 85, goodFormMax: 105, cueGood: "Legs high!", cueBad: "Lower slow!");
  static const russianTwists = ExerciseRule(id: 'russian_twists', name: 'Russian Twists', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 90, contractedAngle: 70, goodFormMin: 60, goodFormMax: 85, cueGood: "Twist!", cueBad: "Feet up!", cameraPosition: 'FRONT');
  static const mountainClimbers = ExerciseRule(id: 'mountain_climbers', name: 'Mountain Climbers', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 170, contractedAngle: 85, goodFormMin: 75, goodFormMax: 100, cueGood: "Fast feet!", cueBad: "Knees to chest!");
  static const bicycleCrunches = ExerciseRule(id: 'bicycle_crunches', name: 'Bicycle Crunches', jointA: _lel, jointB: _kn, jointC: _ak, extendedAngle: 160, contractedAngle: 75, goodFormMin: 65, goodFormMax: 90, cueGood: "Cycle!", cueBad: "Touch elbows!");
  static const hangingLegRaise = ExerciseRule(id: 'hanging_leg_raise', name: 'Hanging Leg Raise', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 175, contractedAngle: 90, goodFormMin: 85, goodFormMax: 105, cueGood: "High legs!", cueBad: "Full raise!");
  static const abWheelRollout = ExerciseRule(id: 'ab_wheel_rollout', name: 'Ab Wheel Rollout', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 175, contractedAngle: 110, goodFormMin: 100, goodFormMax: 125, cueGood: "Roll deep!", cueBad: "Tight core!");
  static const woodchoppers = ExerciseRule(id: 'woodchoppers', name: 'Woodchoppers', jointA: _hp, jointB: _sh, jointC: _wr, extendedAngle: 160, contractedAngle: 90, goodFormMin: 80, goodFormMax: 110, cueGood: "Full swing!", cueBad: "Rotate!", cameraPosition: 'FRONT');
  static const declineSitUp = ExerciseRule(id: 'decline_sit_up', name: 'Decline Sit-Up', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 165, contractedAngle: 50, goodFormMin: 40, goodFormMax: 65, cueGood: "Great crunch!", cueBad: "Full sit!");
  static const cableCrunch = ExerciseRule(id: 'cable_crunch', name: 'Cable Crunch', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 165, contractedAngle: 70, goodFormMin: 60, goodFormMax: 80, cueGood: "Crunch!", cueBad: "Feel the abs!");
  static const plankHold = ExerciseRule(id: 'plank_hold', name: 'Plank Hold', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 175, contractedAngle: 175, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Hold it!", cueBad: "Hips level!");
  static const deadBug = ExerciseRule(id: 'dead_bug', name: 'Dead Bug', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 160, contractedAngle: 90, goodFormMin: 85, goodFormMax: 105, cueGood: "Slow!", cueBad: "Back flat!");

  // ==================== BODYWEIGHT/HOME ====================
  static const airSquats = ExerciseRule(id: 'air_squats', name: 'Air Squats', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 175, contractedAngle: 85, goodFormMin: 75, goodFormMax: 100, cueGood: "Nice squat!", cueBad: "Go lower!");
  static const gluteBridge = ExerciseRule(id: 'glute_bridge', name: 'Glute Bridge', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 120, contractedAngle: 175, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Squeeze!", cueBad: "Hips up!");
  static const supermanRaises = ExerciseRule(id: 'superman_raises', name: 'Superman Raises', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 180, contractedAngle: 160, goodFormMin: 155, goodFormMax: 170, cueGood: "Fly high!", cueBad: "Lift limbs!");
  static const donkeyKicks = ExerciseRule(id: 'donkey_kicks', name: 'Donkey Kicks', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 95, contractedAngle: 155, countOnContraction: false, goodFormMin: 145, goodFormMax: 170, cueGood: "Kick!", cueBad: "Full lift!");
  static const fireHydrants = ExerciseRule(id: 'fire_hydrants', name: 'Fire Hydrants', jointA: _lkn, jointB: _hp, jointC: _kn, extendedAngle: 20, contractedAngle: 75, goodFormMin: 65, goodFormMax: 90, cueGood: "Lift!", cueBad: "Leg sideways!", cameraPosition: 'FRONT');
  static const clamshells = ExerciseRule(id: 'clamshells', name: 'Clamshells', jointA: _lkn, jointB: _hp, jointC: _kn, extendedAngle: 20, contractedAngle: 60, goodFormMin: 50, goodFormMax: 80, cueGood: "Open!", cueBad: "Open wider!", cameraPosition: 'FRONT');
  static const birdDog = ExerciseRule(id: 'bird_dog', name: 'Bird Dog', jointA: _wr, jointB: _sh, jointC: _hp, extendedAngle: 175, contractedAngle: 175, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Stable!", cueBad: "Parallel limb!");
  static const bearCrawls = ExerciseRule(id: 'bear_crawls', name: 'Bear Crawls', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 95, contractedAngle: 95, countOnContraction: false, goodFormMin: 90, goodFormMax: 110, cueGood: "Stay low!", cueBad: "Knees down!");
  static const highKnees = ExerciseRule(id: 'high_knees', name: 'High Knees', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 175, contractedAngle: 90, goodFormMin: 80, goodFormMax: 105, cueGood: "High!", cueBad: "Lift higher!", cameraPosition: 'FRONT');
  static const burpees = ExerciseRule(id: 'burpees', name: 'Burpees', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 175, contractedAngle: 95, goodFormMin: 85, goodFormMax: 110, cueGood: "Fast!", cueBad: "Chest to floor!");
  static const boxJumps = ExerciseRule(id: 'box_jumps', name: 'Box Jumps', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 175, contractedAngle: 90, goodFormMin: 80, goodFormMax: 110, cueGood: "Soft landing!", cueBad: "High jump!");
  static const jumpingJacks = ExerciseRule(id: 'jumping_jacks', name: 'Jumping Jacks', jointA: _wr, jointB: _sh, jointC: _lsh, extendedAngle: 170, contractedAngle: 45, countOnContraction: false, goodFormMin: 160, goodFormMax: 185, cueGood: "Rhythmic!", cueBad: "Full motion!", cameraPosition: 'FRONT');
  static const buttKicks = ExerciseRule(id: 'butt_kicks', name: 'Butt Kicks', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 170, contractedAngle: 40, goodFormMin: 30, goodFormMax: 55, cueGood: "Heels up!", cueBad: "Kick higher!");
  static const skaters = ExerciseRule(id: 'skaters', name: 'Skaters', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 175, contractedAngle: 120, goodFormMin: 110, goodFormMax: 140, cueGood: "Lateral!", cueBad: "Wider!", cameraPosition: 'FRONT');
  static const tuckJumps = ExerciseRule(id: 'tuck_jumps', name: 'Tuck Jumps', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 175, contractedAngle: 70, goodFormMin: 60, goodFormMax: 85, cueGood: "Tuck tight!", cueBad: "Knees up!");
  static const starJumps = ExerciseRule(id: 'star_jumps', name: 'Star Jumps', jointA: _wr, jointB: _sh, jointC: _lsh, extendedAngle: 170, contractedAngle: 45, countOnContraction: false, goodFormMin: 160, goodFormMax: 185, cueGood: "Spread!", cueBad: "Full extension!", cameraPosition: 'FRONT');
  static const lateralHops = ExerciseRule(id: 'lateral_hops', name: 'Lateral Hops', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 175, contractedAngle: 130, goodFormMin: 120, goodFormMax: 145, cueGood: "Quick!", cueBad: "Side to side!", cameraPosition: 'FRONT');
  static const sprawls = ExerciseRule(id: 'sprawls', name: 'Sprawls', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 175, contractedAngle: 100, goodFormMin: 90, goodFormMax: 115, cueGood: "Fast!", cueBad: "Hips down!");
  static const battleRopes = ExerciseRule(id: 'battle_ropes', name: 'Battle Ropes', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 160, contractedAngle: 80, goodFormMin: 70, goodFormMax: 95, cueGood: "Big waves!", cueBad: "Keep rhythm!");
  static const plankJacks = ExerciseRule(id: 'plank_jacks', name: 'Plank Jacks', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 175, contractedAngle: 175, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Fast feet!", cueBad: "Hips stable!");
  static const jumpLunges = ExerciseRule(id: 'jump_lunges', name: 'Jump Lunges', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 170, contractedAngle: 95, goodFormMin: 85, goodFormMax: 105, cueGood: "Explosive!", cueBad: "Deep lunge!");
  static const plankToPushup = ExerciseRule(id: 'plank_to_pushup', name: 'Plank to Push-up', jointA: _sh, jointB: _el, jointC: _wr, extendedAngle: 165, contractedAngle: 90, goodFormMin: 85, goodFormMax: 100, cueGood: "Smooth!", cueBad: "Stay straight!");

  // ==================== BANDED EXERCISES ====================
  static const bandedSquat = ExerciseRule(id: 'banded_squat', name: 'Banded Squat', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 175, contractedAngle: 90, goodFormMin: 80, goodFormMax: 105, cueGood: "Knees out!", cueBad: "Deep squat!");
  static const bandedGluteBridge = ExerciseRule(id: 'banded_glute_bridge', name: 'Banded Glute Bridge', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 125, contractedAngle: 175, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Push knees!", cueBad: "Bridge high!");
  static const bandedClamshell = ExerciseRule(id: 'banded_clamshell', name: 'Banded Clamshell', jointA: _lkn, jointB: _hp, jointC: _kn, extendedAngle: 20, contractedAngle: 60, goodFormMin: 50, goodFormMax: 80, cueGood: "Open!", cueBad: "Open wider!", cameraPosition: 'FRONT');
  static const bandedKickback = ExerciseRule(id: 'banded_kickback', name: 'Banded Kickback', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 170, contractedAngle: 140, goodFormMin: 130, goodFormMax: 155, cueGood: "Strong kick!", cueBad: "Extend leg!");
  static const bandedLateralWalk = ExerciseRule(id: 'banded_lateral_walk', name: 'Banded Lateral Walk', jointA: _lhp, jointB: _hp, jointC: _kn, extendedAngle: 170, contractedAngle: 170, countOnContraction: false, goodFormMin: 165, goodFormMax: 180, cueGood: "Wide steps!", cueBad: "Stay low!", cameraPosition: 'FRONT');
  static const bandedFireHydrant = ExerciseRule(id: 'banded_fire_hydrant', name: 'Banded Fire Hydrant', jointA: _lkn, jointB: _hp, jointC: _kn, extendedAngle: 20, contractedAngle: 75, goodFormMin: 65, goodFormMax: 90, cueGood: "Lift high!", cueBad: "Leg sideways!", cameraPosition: 'FRONT');

  // ==================== BOOTY SPECIFIC ====================
  static const frogPumps = ExerciseRule(id: 'frog_pumps', name: 'Frog Pumps', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 120, contractedAngle: 175, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Squeeze!", cueBad: "Hips up!");
  static const sumoSquatPulse = ExerciseRule(id: 'sumo_squat_pulse', name: 'Sumo Squat Pulse', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 100, contractedAngle: 90, goodFormMin: 85, goodFormMax: 105, cueGood: "Pulse!", cueBad: "Stay low!", cameraPosition: 'FRONT');
  static const curtsyLunges = ExerciseRule(id: 'curtsy_lunges', name: 'Curtsy Lunges', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 170, contractedAngle: 95, goodFormMin: 85, goodFormMax: 105, cueGood: "Cross back!", cueBad: "Deep curtsy!");
  static const gluteBridgeHold = ExerciseRule(id: 'glute_bridge_hold', name: 'Glute Bridge Hold', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 175, contractedAngle: 175, countOnContraction: false, goodFormMin: 170, goodFormMax: 185, cueGood: "Hold it!", cueBad: "Squeeze!");
  static const donkeyKickPulses = ExerciseRule(id: 'donkey_kick_pulses', name: 'Donkey Kick Pulses', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 150, contractedAngle: 155, countOnContraction: false, goodFormMin: 145, goodFormMax: 165, cueGood: "Pulse!", cueBad: "Small pulses!");
  static const squatToKickback = ExerciseRule(id: 'squat_to_kickback', name: 'Squat to Kickback', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 175, contractedAngle: 90, goodFormMin: 80, goodFormMax: 105, cueGood: "Kick back!", cueBad: "Full squat!");
  static const singleLegDeadlift = ExerciseRule(id: 'single_leg_deadlift', name: 'Single Leg Deadlift', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 175, contractedAngle: 95, goodFormMin: 85, goodFormMax: 110, cueGood: "Balance!", cueBad: "Flat back!");
  static const donkeyKicksCable = ExerciseRule(id: 'donkey_kicks_cable', name: 'Donkey Kicks (Cable)', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 95, contractedAngle: 155, countOnContraction: false, goodFormMin: 145, goodFormMax: 170, cueGood: "Squeeze!", cueBad: "Full lift!");

  // ==================== STRETCHES ====================
  static const catCow = ExerciseRule(id: 'cat_cow', name: 'Cat-Cow', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 160, contractedAngle: 140, countOnContraction: false, goodFormMin: 135, goodFormMax: 165, cueGood: "Flow!", cueBad: "Arch back!");
  static const worldsGreatestStretch = ExerciseRule(id: 'worlds_greatest_stretch', name: "World's Greatest Stretch", jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 130, contractedAngle: 130, countOnContraction: false, goodFormMin: 120, goodFormMax: 145, cueGood: "Deep!", cueBad: "Rotate!");
  static const pigeonPose = ExerciseRule(id: 'pigeon_pose', name: 'Pigeon Pose', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 80, contractedAngle: 80, countOnContraction: false, goodFormMin: 70, goodFormMax: 90, cueGood: "Hold!", cueBad: "Square hips!", cameraPosition: 'FRONT');
  static const hamstringStretch = ExerciseRule(id: 'hamstring_stretch', name: 'Hamstring Stretch', jointA: _sh, jointB: _hp, jointC: _ak, extendedAngle: 90, contractedAngle: 90, countOnContraction: false, goodFormMin: 80, goodFormMax: 105, cueGood: "Feel it!", cueBad: "Reach!");
  static const quadStretch = ExerciseRule(id: 'quad_stretch', name: 'Quad Stretch', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 30, contractedAngle: 30, countOnContraction: false, goodFormMin: 20, goodFormMax: 45, cueGood: "Pull!", cueBad: "Leg behind!");
  static const childsPose = ExerciseRule(id: 'childs_pose', name: "Child's Pose", jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 45, contractedAngle: 45, countOnContraction: false, goodFormMin: 35, goodFormMax: 60, cueGood: "Breathe!", cueBad: "Sit back!");
  static const chestDoorwayStretch = ExerciseRule(id: 'chest_doorway_stretch', name: 'Chest Doorway Stretch', jointA: _wr, jointB: _sh, jointC: _lsh, extendedAngle: 160, contractedAngle: 160, countOnContraction: false, goodFormMin: 150, goodFormMax: 175, cueGood: "Open!", cueBad: "Lean in!");
  static const stretch9090 = ExerciseRule(id: '90_90_stretch', name: '90/90 Stretch', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 90, contractedAngle: 90, countOnContraction: false, goodFormMin: 85, goodFormMax: 95, cueGood: "Hold!", cueBad: "Square torso!", cameraPosition: 'FRONT');
  static const frogStretch = ExerciseRule(id: 'frog_stretch', name: 'Frog Stretch', jointA: _lkn, jointB: _hp, jointC: _kn, extendedAngle: 120, contractedAngle: 120, countOnContraction: false, goodFormMin: 110, goodFormMax: 140, cueGood: "Open!", cueBad: "Knees wide!", cameraPosition: 'FRONT');
  static const hipFlexorStretch = ExerciseRule(id: 'hip_flexor_stretch', name: 'Hip Flexor Stretch', jointA: _sh, jointB: _hp, jointC: _kn, extendedAngle: 160, contractedAngle: 160, countOnContraction: false, goodFormMin: 150, goodFormMax: 175, cueGood: "Stretch!", cueBad: "Lunge forward!");
  static const butterflyStretch = ExerciseRule(id: 'butterfly_stretch', name: 'Butterfly Stretch', jointA: _lkn, jointB: _hp, jointC: _kn, extendedAngle: 45, contractedAngle: 45, countOnContraction: false, goodFormMin: 35, goodFormMax: 60, cueGood: "Relax!", cueBad: "Knees down!", cameraPosition: 'FRONT');
  static const happyBaby = ExerciseRule(id: 'happy_baby', name: 'Happy Baby', jointA: _hp, jointB: _kn, jointC: _ak, extendedAngle: 90, contractedAngle: 90, countOnContraction: false, goodFormMin: 80, goodFormMax: 100, cueGood: "Relax!", cueBad: "Knees wide!", cameraPosition: 'FRONT');

  // ==================== LOOKUP MAP - ALL IDS FROM workout_data.dart ====================
  static final Map<String, ExerciseRule> _ruleMap = {
    // CHEST - muscleSplits
    'bench_press': benchPress,
    'incline_press': inclinePress,
    'decline_press': declinePress,
    'chest_flys': chestFlys,
    'pushups': pushUps,
    'push_ups': pushUps,
    'dips_chest': dipsChest,
    'chest_dips': dipsChest,
    'cable_crossover': cableCrossovers,
    'cable_crossovers': cableCrossovers,
    'landmine_press': landminePress,
    // CHEST - gymMuscleSplits (WorkoutPreset IDs)
    'barbell_bench_press': benchPress,
    'incline_db_press': inclinePress,
    'decline_bench_press': declinePress,
    'machine_chest_fly': machineFly,
    'dumbbell_flyes': dumbbellFlyes,
    
    // BACK - muscleSplits
    'deadlift': deadlift,
    'bent_rows': bentOverRows,
    'bent_over_rows': bentOverRows,
    'pullups': pullUps,
    'pull_ups': pullUps,
    'lat_pulldown': latPulldowns,
    'lat_pulldowns': latPulldowns,
    'cable_rows': cableRows,
    'tbar_rows': tBarRows,
    't_bar_rows': tBarRows,
    'face_pulls': facePulls,
    'reverse_flys': reverseFlys,
    'reverse_fly': reverseFlys,
    'shrugs': shrugs,
    'barbell_shrugs': shrugs,
    // BACK - gymMuscleSplits
    'barbell_row': bentOverRows,
    'seated_cable_row': cableRows,
    'tbar_row': tBarRows,
    'single_arm_db_row': singleArmDbRow,
    'renegade_rows': renegadeRows,
    'dumbbell_row': singleArmDbRow,
    
    // SHOULDERS - muscleSplits
    'overhead_press': overheadPress,
    'arnold_press': arnoldPress,
    'lateral_raises': lateralRaises,
    'lateral_raise': lateralRaises,
    'front_raises': frontRaises,
    'front_raise': frontRaises,
    'rear_delt_flys': rearDeltFlys,
    'upright_rows': uprightRows,
    'pike_pushups': pikePushUps,
    'pike_push_ups': pikePushUps,
    // SHOULDERS - gymMuscleSplits
    'seated_db_press': seatedDbPress,
    'cable_lateral_raise': cableLateralRaise,
    'shoulder_press': overheadPress,
    'plank_shoulder_taps': plankShoulderTaps,
    
    // LEGS - muscleSplits
    'squats': squats,
    'romanian_deadlift': romanianDeadlift,
    'rdl': romanianDeadlift,
    'lunges': lunges,
    'lunge': lunges,
    'bulgarian_split': bulgarianSplitSquat,
    'bulgarian_split_squat': bulgarianSplitSquat,
    'leg_press': legPress,
    'leg_extensions': legExtensions,
    'leg_extension': legExtensions,
    'leg_curls': legCurls,
    'leg_curl': legCurls,
    'calf_raises': calfRaises,
    'step_ups': stepUps,
    'goblet_squats': gobletSquats,
    'wall_sits': wallSits,
    'wall_sit': wallSits,
    'jump_squats': jumpSquats,
    // LEGS - gymMuscleSplits
    'back_squat': squats,
    'front_squat': frontSquat,
    'hip_thrust': hipThrust,
    'glute_kickback': gluteKickbackMachine,
    'standing_calf_raise': standingCalfRaise,
    'sumo_squat': sumoSquat,
    'cable_pullthrough': cablePullthrough,
    'cable_kickback': cableKickback,
    'kettlebell_swings': kettlebellSwings,
    'walking_lunges': walkingLunges,
    'box_stepups': stepUps,
    'box_step_ups': stepUps,
    'leg_press_high': legPressHigh,
    'barbell_hip_thrust': hipThrust,
    'sumo_deadlift': sumoDeadlift,
    'glute_bridge_single': singleLegGluteBridge,
    'single_leg_glute_bridge': singleLegGluteBridge,
    'donkey_kicks_cable': donkeyKicksCable,
    'stepups_chair': stepUps,
    
    // ARMS - muscleSplits
    'bicep_curls': bicepCurls,
    'hammer_curls': hammerCurls,
    'hammer_curl': hammerCurls,
    'preacher_curls': preacherCurls,
    'preacher_curl': preacherCurls,
    'tricep_extensions': tricepExtensions,
    'skull_crushers': skullCrushers,
    'overhead_tricep': overheadTricepExtension,
    'overhead_tricep_ext': overheadTricepExtension,
    'overhead_tricep_extension': overheadTricepExtension,
    'close_grip_pushups': closeGripPushUps,
    'close_grip_push_ups': closeGripPushUps,
    'concentration_curls': concentrationCurls,
    'concentration_curl': concentrationCurls,
    'cable_curls': cableCurls,
    'cable_curl': cableCurls,
    'diamond_pushups': diamondPushUps,
    'diamond_push_ups': diamondPushUps,
    // ARMS - gymMuscleSplits
    'barbell_curl': barbellCurl,
    'tricep_pushdown': tricepPushdown,
    'close_grip_bench': closeGripBench,
    'tricep_dips': tricepDips,
    'tricep_dips_chair': tricepDipsChair,
    
    // CORE - muscleSplits
    'situps': sitUps,
    'sit_ups': sitUps,
    'crunches': crunches,
    'planks': plank,
    'plank': plank,
    'side_planks': sidePlank,
    'side_plank': sidePlank,
    'leg_raises': legRaises,
    'russian_twists': russianTwists,
    'russian_twist': russianTwists,
    'mountain_climbers': mountainClimbers,
    'bicycle_crunches': bicycleCrunches,
    // CORE - gymMuscleSplits
    'cable_crunch': cableCrunch,
    'hanging_leg_raise': hangingLegRaise,
    'ab_wheel_rollout': abWheelRollout,
    'woodchoppers': woodchoppers,
    'decline_situp': declineSitUp,
    'decline_sit_up': declineSitUp,
    'plank_hold': plankHold,
    'dead_bug': deadBug,
    
    // CARDIO
    'burpees': burpees,
    'jumping_jacks': jumpingJacks,
    'high_knees': highKnees,
    'butt_kicks': buttKicks,
    'box_jumps': boxJumps,
    'bear_crawls': bearCrawls,
    'sprawls': sprawls,
    'skaters': skaters,
    'tuck_jumps': tuckJumps,
    'star_jumps': starJumps,
    'lateral_hops': lateralHops,
    'battle_ropes': battleRopes,
    'squat_jumps': jumpSquats,
    'plank_jacks': plankJacks,
    'jump_lunges': jumpLunges,
    'plank_to_pushup': plankToPushup,
    
    // HOME BODYWEIGHT
    'air_squats': airSquats,
    'squats_bw': airSquats,
    'glute_bridge': gluteBridge,
    'superman_raises': supermanRaises,
    'superman': supermanRaises,
    'wide_pushups': widePushUps,
    'wide_push_ups': widePushUps,
    
    // HOME BOOTY
    'donkey_kicks': donkeyKicks,
    'fire_hydrants': fireHydrants,
    'clamshells': clamshells,
    'frog_pumps': frogPumps,
    'sumo_squat_pulse': sumoSquatPulse,
    'curtsy_lunges': curtsyLunges,
    'glute_bridge_hold': gluteBridgeHold,
    'donkey_kick_pulses': donkeyKickPulses,
    'squat_to_kickback': squatToKickback,
    'single_leg_deadlift': singleLegDeadlift,
    
    // BANDED
    'banded_squat': bandedSquat,
    'banded_glute_bridge': bandedGluteBridge,
    'banded_clamshell': bandedClamshell,
    'banded_kickback': bandedKickback,
    'banded_lateral_walk': bandedLateralWalk,
    'banded_fire_hydrant': bandedFireHydrant,
    
    // STRETCHES
    'cat_cow': catCow,
    'worlds_greatest_stretch': worldsGreatestStretch,
    'pigeon_pose': pigeonPose,
    'hamstring_stretch': hamstringStretch,
    'quad_stretch': quadStretch,
    'childs_pose': childsPose,
    'chest_doorway_stretch': chestDoorwayStretch,
    '90_90_stretch': stretch9090,
    'frog_stretch': frogStretch,
    'hip_flexor_stretch': hipFlexorStretch,
    'butterfly_stretch': butterflyStretch,
    'happy_baby': happyBaby,
  };

  static ExerciseRule? getRule(String id) => _ruleMap[id.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')];
  static bool hasRule(String id) => getRule(id) != null;
  static int get exerciseCount => _ruleMap.length;
  static List<String> get allExerciseIds => _ruleMap.keys.toList();
}
