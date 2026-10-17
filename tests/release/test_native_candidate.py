"""Keep native release evidence separate from the historical Flutter candidate."""
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/release"))
import check_native_candidate as verifier


class NativeCandidateTests(unittest.TestCase):
    def test_current_candidate_matches_packaged_inputs(self):
        verifier.check()

    def test_stale_app_identity_is_rejected(self):
        candidate = json.loads(verifier.CANDIDATE.read_text())
        candidate['app']['version'] = '1.0.0'
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'candidate.json'
            path.write_text(json.dumps(candidate))
            with patch.object(verifier, 'CANDIDATE', path):
                with self.assertRaisesRegex(ValueError, 'MARKETING_VERSION'):
                    verifier.check()

    def test_resource_hash_drift_is_rejected(self):
        original = verifier.digest

        def drift(path):
            if path == verifier.ROOT / 'app/assets/database/user_v1.sql':
                return '0' * 64
            return original(path)

        with patch.object(verifier, 'digest', side_effect=drift):
            with self.assertRaisesRegex(ValueError, 'Resource closure'):
                verifier.check()
