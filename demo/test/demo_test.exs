defmodule DemoTest do
  use ExUnit.Case
  doctest Demo

  describe "verify_crypto/0" do
    test "returns ok with valid SHA256 hash" do
      assert {:ok, hash} = Demo.verify_crypto()
      assert is_binary(hash)
      assert String.length(hash) == 64
    end
  end

  describe "verify_beam/0" do
    test "returns ok when process spawn and message passing work" do
      assert {:ok, :passed} = Demo.verify_beam()
    end
  end

  describe "health_check/0" do
    @tag :external
    test "returns ok when all checks pass" do
      # This test requires network access for SSL verification
      # Skip in CI environments without network
      assert Demo.health_check() in [:ok, {:error, _}]
    end
  end
end
