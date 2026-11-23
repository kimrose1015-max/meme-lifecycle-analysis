"""Audit historical CSV snapshots using only the Python standard library."""
import csv
import unicodedata
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(name):
    with (ROOT / 'results' / 'original' / name).open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))

def key(name):
    return unicodedata.normalize('NFC', name)

for name in ['예측결과.csv', '실제결과.csv', '병합.csv']:
    rows = read(name)
    print(name, 'rows=', len(rows), dict(Counter(r.get('type', r.get('predicted')) for r in rows)))
merged = read('병합.csv')
valid = [r for r in merged if r['predicted'] in {'단기', '장기'} and r['actual'] in {'단기', '장기'}]
correct = sum(r['predicted'] == r['actual'] for r in valid)
print(f'Merged snapshot: {correct}/{len(valid)} = {correct / len(valid):.1%}')
print('Confusion counts (actual, predicted):', dict(Counter((r['actual'], r['predicted']) for r in valid)))
predictions = {key(r['file']): r['type'] for r in read('예측결과.csv')}
changed = [r for r in merged if key(r['file']) in predictions and predictions[key(r['file'])] != r['predicted']]
print('Prediction labels differing between snapshots:', len(changed))
print('These snapshots do not establish the presentation metrics.')
