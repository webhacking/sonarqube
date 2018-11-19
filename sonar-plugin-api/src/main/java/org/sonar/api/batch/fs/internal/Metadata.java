/*
 * SonarQube
 * Copyright (C) 2009-2018 SonarSource SA
 * mailto:info AT sonarsource DOT com
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
package org.sonar.api.batch.fs.internal;

import java.util.Arrays;

import javax.annotation.concurrent.Immutable;

@Immutable
public class Metadata {
  private final int lines;
  private final int nonBlankLines;
  private final String hash;
  private final int[] originalLineOffsets;
  private final int lastValidOffset;

  public Metadata(int lines, int nonBlankLines, String hash, int[] originalLineOffsets, int lastValidOffset) {
    this.lines = lines;
    this.nonBlankLines = nonBlankLines;
    this.hash = hash;
    this.originalLineOffsets = Arrays.copyOf(originalLineOffsets, originalLineOffsets.length);
    this.lastValidOffset = lastValidOffset;
  }

  public int lines() {
    return lines;
  }

  public int nonBlankLines() {
    return nonBlankLines;
  }

  public String hash() {
    return hash;
  }

  public int[] originalLineOffsets() {
    return originalLineOffsets;
  }

  public int lastValidOffset() {
    return lastValidOffset;
  }

}
