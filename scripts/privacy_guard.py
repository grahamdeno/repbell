#!/usr/bin/env python3
"""Rep Bell privacy guard. Enforces the on-device promise in CI.

Rep Bell has no account, no server, no analytics and no third-party SDKs. The only data that leaves the app is a
finished session written to Apple Health, write only, when the person allows it. Generated coach media is allowed
only while `Features.coachMedia` is true (TestFlight testing while requirement R-1 is open, decision of 23 Nov 2026),
and only as .mp4 and .png files in App/Studio/Coach. Video anywhere else in the build always fails.

Usage:
    python3 scripts/privacy_guard.py              check the repo; exit 1 on any violation
    python3 scripts/privacy_guard.py --self-test  prove every rule catches what it should; exit 1 if one doesn't
"""
import pathlib
import plistlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE_DIRS = ["App", "Watch", "Widget", "Packages/RepBellEngine/Sources"]

IMPORT = r"^\s*(?:@\w+\s+)*import\s+(?:\w+\s+)?"

# (rule name, pattern, why)
SOURCE_RULES = [
    ("network: URLSession", re.compile(r"\bURLSession\b"), "no network calls"),
    ("network: Network framework", re.compile(IMPORT + r"Network\b", re.M), "no network calls"),
    ("network: sockets", re.compile(r"\b(NWConnection|NWListener|CFStream|InputStream\(url|OutputStream\(url)\b"), "no network calls"),
    ("network: web URL literal", re.compile(r"\"https?://"), "no web addresses in code"),
    ("network: remote loaders", re.compile(r"\b(URLComponents|AVPlayer\(url|AsyncImage\()"), "no remote media or built-up web addresses"),
    ("network: WebKit", re.compile(IMPORT + r"WebKit\b", re.M), "no web views"),
    ("network: CloudKit", re.compile(IMPORT + r"CloudKit\b", re.M), "no cloud sync"),
    ("analytics or SDK", re.compile(
        IMPORT + r"(Firebase\w*|Crashlytics|Sentry|Amplitude\w*|Mixpanel|Segment\w*|"
        r"AppsFlyer\w*|Adjust\w*|FBSDK\w*|FacebookCore|Bugsnag|Datadog\w*|PostHog|RevenueCat|Purchases|"
        r"OneSignal\w*|Branch|Heap|Instabug)\b", re.M), "no analytics or third-party SDKs"),
]

HEALTH_CALL = re.compile(r"requestAuthorization\s*\(")
HEALTH_READ = re.compile(r"\bread\s*:\s*(\[[^\]]*\]|[\w.]+)", re.S)


def health_reads(text):
    """True when any HealthKit authorization request asks to read something."""
    for call in HEALTH_CALL.finditer(text):
        window = text[call.end():call.end() + 600]
        if "toShare" not in window[:200]:
            continue
        match = HEALTH_READ.search(window)
        if match and re.sub(r"\s", "", match.group(1)) != "[]":
            return True
    return False


def violations_in_source(text):
    found = [(name, why) for name, pattern, why in SOURCE_RULES if pattern.search(text)]
    if health_reads(text):
        found.append(("Health read access", "Health is write only"))
    return found


ENTITLEMENT_BANS = ("com.apple.developer.icloud", "ubiquity", "aps-environment", "com.apple.developer.healthkit.access")


def violations_in_entitlements(data):
    found = []
    for key, value in data.items():
        if key == "com.apple.developer.healthkit.access":
            if value:
                found.append(("Health read access", f"entitlement {key} lists {value}"))
            continue
        if any(key.startswith(ban) for ban in ENTITLEMENT_BANS):
            found.append(("cloud or push", f"entitlement {key}"))
    return found


def violations_in_plist(data):
    """Apple requires NSHealthShareUsageDescription in every HealthKit app, even one that never reads.
    So the key may be present, but its text must say Rep Bell doesn't read Health data."""
    found = []
    text = data.get("NSHealthShareUsageDescription")
    if text is not None and "does not read" not in text:
        found.append(("Health read access", "Info.plist's Health read text must say Rep Bell does not read Health data"))
    return found


def violations_in_pbxproj(text):
    if "XCRemoteSwiftPackageReference" in text:
        return [("third-party package", "the Xcode project pulls a remote Swift package")]
    return []


def violations_in_package(text):
    if re.search(r"\.package\(\s*url:", text):
        return [("third-party package", "Package.swift depends on a remote package")]
    return []


MEDIA = {".mp4", ".mov", ".m4v", ".gif", ".webm", ".mkv", ".avi", ".mpg", ".mpeg", ".3gp", ".m2ts", ".hevc"}


COACH_DIR = ("App", "Studio", "Coach")
COACH_ALLOWED = {".mp4", ".png"}


def coach_media_on(features_text):
    """True only when Features.swift sets `coachMedia = true` exactly once, outside comments and #if blocks."""
    code = re.sub(r"/\*.*?\*/", "", features_text, flags=re.S)
    code = re.sub(r"//[^\n]*", "", code)
    if re.search(r"^\s*#if\b", code, flags=re.M):
        return False
    found = re.findall(r"^\s*public\s+static\s+let\s+coachMedia\s*=\s*(true|false)\b", code, flags=re.M)
    return found == ["true"]


def violations_in_paths(paths, coach_media=False):
    found = []
    for path in paths:
        parts = path.parts
        in_coach = parts[:3] == COACH_DIR
        if in_coach and coach_media and path.suffix.lower() in COACH_ALLOWED:
            continue
        if path.suffix.lower() in MEDIA and parts and parts[0] in ("App", "Watch", "Widget"):
            found.append(("coach media", f"video file in the build: {path}"))
        elif "Coach" in parts and parts[0] == "App":
            found.append(("coach media", f"coach folder in the build: {path}"))
    return found


def check_repo():
    problems = []
    for folder in SOURCE_DIRS:
        base = ROOT / folder
        files = sorted(base.rglob("*.swift")) if base.is_dir() else []
        if not files:
            problems.append(f"{folder}: missing or has no Swift files, so nothing was checked")
        for file in files:
            for name, why in violations_in_source(file.read_text(encoding="utf-8")):
                problems.append(f"{file.relative_to(ROOT)}: {name} ({why})")
    for ent in sorted(p for p in ROOT.rglob("*.entitlements") if ".git" not in p.parts):
        with ent.open("rb") as handle:
            for name, why in violations_in_entitlements(plistlib.load(handle)):
                problems.append(f"{ent.relative_to(ROOT)}: {name} ({why})")
    for plist in sorted(p for p in ROOT.rglob("Info.plist") if ".git" not in p.parts):
        with plist.open("rb") as handle:
            for name, why in violations_in_plist(plistlib.load(handle)):
                problems.append(f"{plist.relative_to(ROOT)}: {name} ({why})")
    for name, why in violations_in_pbxproj((ROOT / "RepBell.xcodeproj/project.pbxproj").read_text(encoding="utf-8")):
        problems.append(f"RepBell.xcodeproj: {name} ({why})")
    for name, why in violations_in_package((ROOT / "Packages/RepBellEngine/Package.swift").read_text(encoding="utf-8")):
        problems.append(f"Packages/RepBellEngine/Package.swift: {name} ({why})")
    files = [p.relative_to(ROOT) for folder in ("App", "Watch", "Widget") for p in (ROOT / folder).rglob("*") if p.is_file()]
    features = (ROOT / "Packages/RepBellEngine/Sources/RepBellEngine/Features.swift").read_text(encoding="utf-8")
    for name, why in violations_in_paths(files, coach_media=coach_media_on(features)):
        problems.append(f"{name}: {why}")
    return problems


def self_test():
    bad_sources = {
        "network: URLSession": "let task = URLSession.shared.dataTask(with: url)",
        "network: Network framework": "import Network\n",
        "network: sockets": "let c = NWConnection(host: h, port: p, using: .tcp)",
        "network: web URL literal": 'let u = URL(string: "https://example.com")',
        "network: WebKit": "import WebKit\n",
        "network: CloudKit": "import CloudKit\n",
        "analytics or SDK": "import FirebaseAnalytics\n",
        "Health read access": "try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [HKObjectType.workoutType()])",
        "network: remote loaders": "let p = AVPlayer(url: remote)",
    }
    failures = []
    for rule, sample in bad_sources.items():
        if rule not in [name for name, _ in violations_in_source(sample)]:
            failures.append(f"rule '{rule}' missed: {sample!r}")
    clean = (
        "import SwiftUI\nimport HealthKit\n"
        "if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }\n"
        "try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [])\n"
    )
    if violations_in_source(clean):
        failures.append(f"clean source flagged: {violations_in_source(clean)}")
    more_bad = [
        "try await store.requestAuthorization(\n    toShare: [HKObjectType.workoutType()],\n    read: [HKQuantityType(.stepCount)]\n)",
        "try await store.requestAuthorization(toShare: types, read: readTypes)",
        "@preconcurrency import Network\n",
        "@_implementationOnly import FirebaseAnalytics\n",
    ]
    for sample in more_bad:
        if not violations_in_source(sample):
            failures.append(f"missed: {sample!r}")
    more_clean = [
        "try await store.requestAuthorization(toShare: types, read: [])",
        "try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [ ])",
        "try await store.requestAuthorization(\n  toShare: [HKObjectType.workoutType()],\n  read: []\n)",
        "UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])",
    ]
    for sample in more_clean:
        if violations_in_source(sample):
            failures.append(f"clean sample flagged: {sample!r} -> {violations_in_source(sample)}")
    if not violations_in_entitlements({"com.apple.developer.icloud-services": ["CloudKit"]}):
        failures.append("iCloud entitlement missed")
    if not violations_in_entitlements({"aps-environment": "production"}):
        failures.append("push entitlement missed")
    if not violations_in_entitlements({"com.apple.developer.healthkit.access": ["health-records"]}):
        failures.append("Health records entitlement missed")
    if violations_in_entitlements({"com.apple.developer.healthkit": True, "com.apple.developer.healthkit.access": [],
                                   "com.apple.security.application-groups": ["group.x"]}):
        failures.append("allowed entitlements flagged")
    if not violations_in_plist({"NSHealthShareUsageDescription": "Rep Bell reads your workouts."}):
        failures.append("Health read description missed")
    if violations_in_plist({"NSHealthShareUsageDescription": "Rep Bell does not read your Health data."}):
        failures.append("required no-read Health text flagged")
    if violations_in_plist({"NSHealthUpdateUsageDescription": "x"}):
        failures.append("Health write description flagged")
    if not violations_in_pbxproj("XCRemoteSwiftPackageReference \"x\""):
        failures.append("remote package in the project missed")
    if not violations_in_package('.package(url: "https://github.com/x/y", from: "1.0.0")'):
        failures.append("remote package in Package.swift missed")
    if not violations_in_paths([pathlib.PurePosixPath("App/Studio/Coach/her-boat.mp4")]):
        failures.append("coach video missed with coach media off")
    if violations_in_paths([pathlib.PurePosixPath("App/Studio/Coach/her-boat.mp4")], coach_media=True):
        failures.append("coach clip flagged with coach media on")
    if not violations_in_paths([pathlib.PurePosixPath("App/Studio/her-boat.mp4")], coach_media=True):
        failures.append("video outside the coach folder missed with coach media on")
    if not violations_in_paths([pathlib.PurePosixPath("Watch/Coach/her-boat.mp4")], coach_media=True):
        failures.append("video in the Watch app missed with coach media on")
    if not violations_in_paths([pathlib.PurePosixPath("App/Studio/Coach/her-boat.mov")], coach_media=True):
        failures.append("other video type in the coach folder missed")
    if not coach_media_on("public static let coachMedia = true"):
        failures.append("coachMedia = true not read")
    if coach_media_on("public static let coachMedia = false"):
        failures.append("coachMedia = false read as on")
    if coach_media_on("// public static let coachMedia = true\npublic static let coachMedia = false"):
        failures.append("commented-out coachMedia = true read as on")
    if coach_media_on("#if DEBUG\npublic static let coachMedia = true\n#else\npublic static let coachMedia = false\n#endif"):
        failures.append("coachMedia inside #if read as on")
    if coach_media_on("/* public static let coachMedia = true */"):
        failures.append("block-commented coachMedia read as on")
    if not violations_in_paths([pathlib.PurePosixPath("App/x.mkv")]):
        failures.append("mkv video missed")
    if violations_in_paths([pathlib.PurePosixPath("docs/screens/A1.html")]):
        failures.append("docs file flagged")
    return failures


def main():
    if "--self-test" in sys.argv:
        failures = self_test()
        for line in failures:
            print(f"SELF-TEST FAIL: {line}")
        print(f"Self-test: {len(failures)} failure(s).")
        return 1 if failures else 0
    problems = check_repo()
    for line in problems:
        print(f"PRIVACY GUARD: {line}")
    print(f"Privacy guard: {len(problems)} problem(s).")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
