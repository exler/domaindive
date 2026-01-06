<script lang="ts">
    import "../app.css";
</script>

<slot />

<footer class="mt-auto py-4 text-center text-sm text-gray-600">
    Copyright © {new Date().getFullYear()} Kamil Marut |
    <a
        href="https://github.com/exler/domaindive"
        target="_blank"
        rel="noopener noreferrer"
        class="text-blue-600 hover:underline"
    >
        GitHub
    </a>
</footer>
