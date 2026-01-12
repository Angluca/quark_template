# Build tools
QC := qc
CC := gcc

# Entry
MAIN ?= main
MAIN_QK := src/$(MAIN).qk

# Tests
TEST_DIR := tests

# Quark library path
QUARK_ROOT ?=

# Build mode and args
MODE ?= debug
ARGS ?=

# Platform detect
ifeq ($(OS),Windows_NT)
  PLATFORM := windows
else
  UNAME_S := $(shell uname -s)
  ifeq ($(UNAME_S),Darwin)
    PLATFORM := macos
  else
    PLATFORM := linux
  endif
endif

# Platform helpers
ifeq ($(PLATFORM),windows)
  EXE := .exe
  QC = $(QC)$(EXE)
  CC = $(CC)$(EXE)
  MKDIR = if not exist "$(1)" mkdir "$(1)"
  RM_RF = if exist build rmdir /s /q build
else
  EXE :=
  MKDIR = mkdir -p "$(1)"
  RM_RF = rm -rf build
endif

# Build flags
ifeq ($(MODE),debug)
  BUILD := build/debug
  CFLAGS := -O0 -g -Wall -Wextra
  ifneq ($(PLATFORM),windows)
    CFLAGS += -fsanitize=address
    LDFLAGS += -fsanitize=address
  endif
else
  BUILD := build/release
  CFLAGS := -O2 -Wall -Wextra
  LDFLAGS :=
endif

# Output paths
C_OUT := $(BUILD)/c
O_OUT := $(BUILD)/o
T_OUT := $(BUILD)/tests
TARGET := $(BUILD)/$(MAIN)$(EXE)

# Helpers
FLAT = $(subst /,__,$(basename $1))

# Main files
MAIN_C := $(C_OUT)/$(call FLAT,$(MAIN_QK)).c
MAIN_O := $(O_OUT)/$(notdir $(MAIN_C:.c=.o))

# Test files (portable glob)
TEST_QK  := $(sort $(wildcard $(TEST_DIR)/*.qk))
TEST_C   := $(foreach f,$(TEST_QK),$(C_OUT)/$(call FLAT,$(f)).c)
TEST_O   := $(foreach f,$(TEST_C),$(O_OUT)/$(notdir $(f:.c=.o)))
TEST_BIN := $(foreach f,$(TEST_QK),$(T_OUT)/$(call FLAT,$(f))$(EXE))

# Default
all: $(TARGET)

# Run main
run: $(TARGET)
	$(TARGET) $(ARGS)

# Link main
$(TARGET): $(MAIN_O)
	$(call MKDIR,$(BUILD))
	$(CC) $^ $(LDFLAGS) -o $@

# QK -> C (main)
$(MAIN_C): $(MAIN_QK)
	$(call MKDIR,$(C_OUT))
	$(QC) $< -o $@ -l "$(QUARK_ROOT)"

# C -> O
$(O_OUT)/%.o: $(C_OUT)/%.c
	$(call MKDIR,$(O_OUT))
	$(CC) $(CFLAGS) -c $< -o $@

# QK -> C (tests)
define QK_TO_C
$(C_OUT)/$(call FLAT,$(1)).c: $(1)
	$(call MKDIR,$(C_OUT))
	$(QC) $(1) -o $$@ -l "$(QUARK_ROOT)"
endef
$(foreach f,$(TEST_QK),$(eval $(call QK_TO_C,$(f))))

# Link tests
define TEST_LINK
$(T_OUT)/$(call FLAT,$(1))$(EXE): $(O_OUT)/$(call FLAT,$(1)).o
	$(call MKDIR,$(T_OUT))
	$(CC) $$< $(LDFLAGS) -o $$@
endef
$(foreach f,$(TEST_QK),$(eval $(call TEST_LINK,$(f))))

# Tests
test: $(TEST_BIN)

test-run: $(TEST_BIN)
	@$(foreach t,$(TEST_BIN),echo ==> $(t) && $(t) $(ARGS)$(newline))

# Mode shortcuts
release:
	$(MAKE) MODE=release

debug:
	$(MAKE) MODE=debug

# Clean
clean:
	$(RM_RF)

.PHONY: all run test test-run clean release debug

