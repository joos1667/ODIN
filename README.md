# ODIN

GitHub repository for the Blue Team (ODIN) in ASEN 4018, Section 17 (2026–27).

## Branch Structure

The repository uses three levels of branches:

### `main`

The top-level branch containing **fully integrated, polished, and reviewed code**. Updates to `main` are managed by the Data Lead as needed.

### `workingMain`

The integration branch one level below `main`. Polished subteam-level changes are merged here before being integrated into `main`. This branch provides a stable version of the code that other teams can use during development.

**All pull requests into `workingMain` must be reviewed before merging.**

### `subBranches`

Branches used by individuals and subteams to develop and test changes before merging them into `workingMain`.

---

## Development Workflow

When a new coding task is identified, the person or subteam responsible for the task should create a branch from the current `workingMain` branch.

### Subteam Branches

Name subteam branches using:

`Subteam(s)_function/issue_description_main#.workingMain#`

For example:

`CDH_data_compressions_2.3`

This indicates that:

* `CDH` is the responsible subteam.
* `data_compressions` is the function/task being developed.
* `2` indicates that the branch is based on the second version of `main`.
* `3` indicates that it is based on the third version of `workingMain` derived from that `main` version.

### Individual Development Branches

If a task is sufficiently complex to require multiple individuals or additional development branches, use:

`Name_Subteam(s)_function/issue_description_main#.workingMain#.subBranch#`

For example:

`Joe_CDH_data_compressions_2.3.6`

This indicates that Joe is working on the `CDH_data_compressions_2.3` task branch, using sub-branch `6`.

---

## Commit Messages

Every push to a branch must include the branch name and sequential push number in the commit message:

`Branchname.push#: change description`

For example, if Carson and Joe are both working on `CDH_data_compressions_2.3`:

**Carson's first push:**
`CDH_data_compressions_2.3.1: added data read function`

**Joe's second push:**
`CDH_data_compressions_2.3.2: added first compression function`

The push number should increment sequentially for each push to that branch.
