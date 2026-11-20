#!/usr/bin/env python3
"""Rep Bell privacy guard. Enforces the on-device promise in CI.

Rep Bell has no account, no server, no analytics and no third-party SDKs. The only data that leaves the app is a
finished session written to Apple Health, write only, when the person allows it. Generated coach media stays out of
the build until requirement R-1 is met.

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

# (rule name, pattern, why)
SOURCE_RULES = [
    ("network: URLSession", re.compile(r"\bURLSession\b"), "no network calls"),
    ("network: Network framework", re.compile(r"^\s*import\s+Network\b", re.M), "no network calls"),
    ("network: sockets", re.compile(r"\b(NWConnection|NWListener|CFStream|InputStream\(url|OutputStream\(url)\b"), "no network calls"),
    ("network: web URL literal", re.compile(r"\"https?://"), "no web addresses in code"),
    ("network: WebKit", re.compile(r"^\s*import\s+WebKit\b", re.M), "no web views"),
    ("network: CloudKit", re.compile(r"^\s*import\s+CloudKit\b", re.M), "no cloud sync"),
    ("analytics or SDK", re.compile(
        r"^\s*import\s+(Firebase\w*|FirebaseAnalytics|Crashlytics|Sentry|Amplitude\w*|Mixpanel|Segment\w*|"
        r"AppsFlyer\w*|Adjust\w*|FBSDK\w*|FacebookCore|Bugsnag|Datadog\w*|PostHog|RevenueCat|Purchases|"
        r"OneSignal\w*|Branch|Heap|Instabug)\b", re.M), "no analytics or third-party SDKs"),
    ("Health read access", re.compile(r"requestAuthorization\(toShare:[^)]*read:\s*(?!\[\]\s*\))[^)]"), "Health is write only"),
]


def violations_in_source(text):
    return [(name, why) for name, pattern, why in SOURCE_RULES if pattern.search(text)]


def violations_in_plist(data):
    found = []
    if "NSHealthShareUsageDescription" in data:
        found.append(("Health read access", "Info.plist asks to read Health data"))
    return found


def violations_in_pbxproj(text):
    if "XCRemoteSwiftPackageReference" in text:
        return [("third-party package", "the Xcode project pulls a remote Swift package")]
    return []


def violations_in_package(text):
    if re.search(r"\.package\(\s*url:", text):
        return [("third-party package", "Package.swift depends on a remote package")]
    return []


MEDIA = {".mp4", ".mov", ".m4v", ".gif", ".webm"}


def violations_in_paths(paths):
    found = []
    for path in paths:
        parts = path.parts
        if path.suffix.lower() in MEDIA and parts and parts[0] in ("App", "Watch", "Widget"):
            found.append(("coach media", f"video file in the build: {path}"))
        if "Coach" in parts and parts[0] == "App":
            found.append(("coach media", f"coach folder in the build: {path}"))
    return found


def check_repo():
    problems = []
    for folder in SOURCE_DIRS:
        for file in sorted((ROOT / folder).rglob("*.swift")):
            for name, why in violations_in_source(file.read_text(encoding="utf-8")):
                problems.append(f"{file.relative_to(ROOT)}: {name} ({why})")
    for plist in sorted(ROOT.glob("*/Info.plist")):
        with plist.open("rb") as handle:
            for name, why in violations_in_plist(plistlib.load(handle)):
                problems.append(f"{plist.relative_to(ROOT)}: {name} ({why})")
    for name, why in violations_in_pbxproj((ROOT / "RepBell.xcodeproj/project.pbxproj").read_text(encoding="utf-8")):
        problems.append(f"RepBell.xcodeproj: {name} ({why})")
    for name, why in violations_in_package((ROOT / "Packages/RepBellEngine/Package.swift").read_text(encoding="utf-8")):
        problems.append(f"Packages/RepBellEngine/Package.swift: {name} ({why})")
    files = [p.relative_to(ROOT) for p in ROOT.rglob("*") if p.is_file() and ".git" not in p.parts]
    for name, why in violations_in_paths(files):
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
        "Health read access": "try await store.requestAuthorization(toShare: [w], read: [HKObjectType.workoutType()])",
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
    if not violations_in_plist({"NSHealthShareUsageDescription": "x"}):
        failures.append("Health read description missed")
    if violations_in_plist({"NSHealthUpdateUsageDescription": "x"}):
        failures.append("Health write description flagged")
    if not violations_in_pbxproj("XCRemoteSwiftPackageReference \"x\""):
        failures.append("remote package in the project missed")
    if not violations_in_package('.package(url: "https://github.com/x/y", from: "1.0.0")'):
        failures.append("remote package in Package.swift missed")
    if not violations_in_paths([pathlib.PurePosixPath("App/Studio/Coach/her-boat.mp4")]):
        failures.append("coach video missed")
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
