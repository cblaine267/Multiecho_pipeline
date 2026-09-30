#!/usr/bin/env python3

import sys
from pathlib import Path

import nibabel as nib
import numpy as np
import pandas as pd
from scipy.io import loadmat


# ---------------------------------------------------------------------
# Arguments / paths
# ---------------------------------------------------------------------
if len(sys.argv) != 4:
    sys.exit(
        f"Usage: {sys.argv[0]} SUBJECT RUN_DIR PRIORS_FILE"
    )


run_dir = Path(sys.argv[2])
priors_file = Path(sys.argv[3])

tedana_dir = run_dir / "Tedana"
output_dir = run_dir / "Tedana+ManualComponentClassification"

metrics_file = tedana_dir / "desc-tedana_metrics.tsv"
cifti_file = tedana_dir / "desc-ICA_stat-z_components.dtseries.nii"


# ---------------------------------------------------------------------
# Verify inputs
# ---------------------------------------------------------------------




# ---------------------------------------------------------------------
# Load Priors.FC
# MATLAB:
#   load(Priors.mat)
#   TemplateFC = Priors.FC;
# ---------------------------------------------------------------------

mat = loadmat(priors_file)

priors = mat["Priors"]
template_fc = priors["FC"][0, 0]

print("Priors.FC:", template_fc.shape)

if template_fc.shape[0] != 59412:
    sys.exit(
        f"ERROR: Expected Priors.FC to have 59412 rows; "
        f"found {template_fc.shape[0]}"
    )


# ---------------------------------------------------------------------
# Load Tedana component table
# ---------------------------------------------------------------------

metrics = pd.read_csv(metrics_file, sep="\t")

if "classification" not in metrics.columns:
    sys.exit("ERROR: No 'classification' column in Tedana metrics.")

if "Component" not in metrics.columns:
    sys.exit("ERROR: No 'Component' column in Tedana metrics.")

accepted_rows = metrics[
    metrics["classification"].astype(str).str.lower() == "accepted"
].copy()

print(f"Tedana components: {len(metrics)}")
print(f"Initially accepted: {len(accepted_rows)}")


# ---------------------------------------------------------------------
# Convert Tedana component labels to integer component numbers
#
# Usually Tedana uses labels such as:
#   ICA_00
#   ICA_01
#   ...
# ---------------------------------------------------------------------

def component_number(value):
    value = str(value)

    if value.startswith("ICA_"):
        return int(value.split("_")[-1])

    return int(value)


accepted = np.array(
    [component_number(x) for x in accepted_rows["Component"]],
    dtype=int,
)


# ---------------------------------------------------------------------
# Load component CIFTI
#
# nibabel:
#     components x grayordinates
#
# Current J007:
#     769 x 83375
#
# MATLAB/FieldTrip used:
#     IC.dtseries(1:59412, acc+1)
#
# Therefore Python uses:
#     cifti_data[component, :59412]
# ---------------------------------------------------------------------

mat = loadmat(priors_file)
template_fc = mat["Priors"]["FC"][0, 0]
print("Priors.FC:", template_fc.shape)

if template_fc.shape[0] != 59412:
    sys.exit(f"ERROR: Expected Priors.FC to have 59412 rows; found {template_fc.shape[0]}")


# ---------------------------------------------------------------------
# Read metrics table; acc = 0-based row positions classified 'accepted'
# (MATLAB: acc = [acc ii-1] when strcmp(classification, 'accepted'))
# ---------------------------------------------------------------------
metrics = pd.read_csv(metrics_file, sep="\t")

if "classification" not in metrics.columns:
    sys.exit("ERROR: No 'classification' column in Tedana metrics.")

classification = metrics["classification"].astype(str).tolist()
n_comp = len(classification)  # MATLAB: idx = height(json)

acc = np.array([i for i, c in enumerate(classification) if c == "accepted"], dtype=int)
print("acc:", acc.tolist())


# ---------------------------------------------------------------------
# List of component images (MATLAB: dir([... '/figures/*.png']), name-sorted)
# ---------------------------------------------------------------------
images = sorted(p.name for p in figures_dir.glob("*.png"))

# ---------------------------------------------------------------------
# Load IC maps and compute spatial similarity with template networks
# MATLAB: rho = corr(IC.dtseries(1:59412,acc+1), TemplateFC, 'rows','pairwise');
# nibabel data is components x grayordinates.
# ---------------------------------------------------------------------
img = nib.load(cifti_file)
print("CIFTI:", img.shape)

if img.shape[1] < 59412:
    sys.exit(f"ERROR: CIFTI contains only {img.shape[1]} grayordinates.")
if len(acc) and acc.max() >= img.shape[0]:
    sys.exit("ERROR: Accepted component number exceeds CIFTI component count.")

cifti_data = np.asanyarray(img.dataobj)
component_maps = cifti_data[acc, :59412]

rho = np.full((len(acc), template_fc.shape[1]), np.nan, dtype=float)

for i in range(len(acc)):
    x = component_maps[i].astype(float)
    for j in range(template_fc.shape[1]):
        y = template_fc[:, j].astype(float)

        valid = ~np.isnan(x) & ~np.isnan(y)   # 'rows','pairwise'
        if valid.sum() < 2:
            continue

        xv, yv = x[valid], y[valid]
        if np.std(xv) == 0 or np.std(yv) == 0:  # MATLAB corr -> NaN
            continue

        rho[i, j] = np.corrcoef(xv, yv)[0, 1]

print("RHO")
print(rho)

# MATLAB max() ignores NaN; an all-NaN row gives NaN, and NaN < 0.1 is false
with warnings.catch_warnings():
    warnings.simplefilter("ignore", RuntimeWarning)
    max_abs_rho = np.nanmax(np.abs(rho), axis=1) if len(acc) else np.array([])

man_rej_auto = acc[max_abs_rho < 0.1]   # ManRej


# ---------------------------------------------------------------------
# Copy images of ManRej components into figures/ManuallyRejected/
# MATLAB: images(ManRej(ii)+1).name
# ---------------------------------------------------------------------
man_rej_dir.mkdir(parents=True, exist_ok=True)

for c in man_rej_auto:
    if c >= len(images):
        sys.exit(f"ERROR: No figure at sorted index {c} (only {len(images)} PNGs).")
    shutil.copy(figures_dir / images[c], man_rej_dir / images[c])


# ---------------------------------------------------------------------
# Read component numbers back from the ManuallyRejected / ManuallyAccepted
# folders (MATLAB: split name on '_' and '.', take 2nd token, strip zeros)
# ---------------------------------------------------------------------
def numbers_from_folder(folder):
    nums = []
    if not folder.exists():
        return nums
    for p in sorted(folder.glob("*.png")):
        tokens = re.split(r"[_.]", p.name)
        s = tokens[1].lstrip("0") if len(tokens) > 1 else ""
        if s == "":
            s = "0"
        try:
            nums.append(int(s))
        except ValueError:
            print(f"WARNING: could not parse component number from {p.name}")
    return nums


man_rej = numbers_from_folder(man_rej_dir)
man_acc = numbers_from_folder(man_acc_dir)


# ---------------------------------------------------------------------
# Every component not manually rejected and not tedana-rejected is accepted
# ---------------------------------------------------------------------
for i in range(n_comp):
    if (i not in man_rej) and classification[i] != "rejected":
        man_acc.append(i)

man_acc = sorted(man_acc)
man_rej = sorted(man_rej)


# ---------------------------------------------------------------------
# Write lists (MATLAB format: ' 0 3 5' with a leading space, no newline)
# ---------------------------------------------------------------------
output_dir.mkdir(parents=True, exist_ok=True)

accepted_file = output_dir / "AcceptedComponents.txt"
rejected_file = output_dir / "RejectedComponents.txt"

accepted_file.write_text("".join(f" {c}" for c in man_acc))
rejected_file.write_text("".join(f" {c}" for c in man_rej))


# ---------------------------------------------------------------------
# Write CIFTIs: full copy, accepted-only, rejected-only
# (MATLAB wrapped this in try/catch; same here)
# ---------------------------------------------------------------------
try:
    ax_comp = img.header.get_axis(0)
    ax_space = img.header.get_axis(1)

    def subset_axis(indices):
        try:
            return ax_comp[np.asarray(indices, dtype=int)]
        except Exception:
            return nib.cifti2.cifti2_axes.ScalarAxis(
                [f"ICA_{i:02d}" for i in indices]
            )

    def write_cifti(data, indices, path):
        header = nib.cifti2.Cifti2Header.from_axes((subset_axis(indices), ax_space))
        out = nib.Cifti2Image(data, header=header, nifti_header=img.nifti_header)
        nib.save(out, path)

    all_idx = list(range(cifti_data.shape[0]))
    write_cifti(
        cifti_data, all_idx,
        output_dir / "desc-ICA_stat-z_components_from_script.dtseries.nii",
    )

    acc_idx = np.array(man_acc, dtype=int)
    write_cifti(
        cifti_data[acc_idx, :], acc_idx,
        output_dir / "desc-ICA_Accepted.dtseries.nii",
    )

    rej_idx = [i for i in all_idx if i not in set(man_acc)]
    write_cifti(
        cifti_data[rej_idx, :], rej_idx,
        output_dir / "desc-ICA_Rejected.dtseries.nii",
    )
except Exception as e:
    print(f"WARNING: CIFTI output skipped ({e})")


# ---------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------
print()
print("Classification complete.")
print(f"Accepted: {len(man_acc)}")
print(f"Rejected: {len(man_rej)}")
print("Accepted components:", man_acc)
print("Rejected components:", man_rej)
print()
print("Wrote:")
print(accepted_file)
print(rejected_file)
