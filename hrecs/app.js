"use strict";

document.addEventListener("DOMContentLoaded", function () {
    const container = document.getElementById("education-rows");
    const addButton = document.getElementById("add-education");

    if (!container || !addButton) {
        console.error(
            "Education CRUD: missing #education-rows or #add-education."
        );
        return;
    }

    const MAX_ROWS = 20;

    const fields = [
        ["school_name", "School name", 200],
        ["location", "Location", 200],
        ["years_attended", "Years attended", 30],
        ["degree_required", "Degree", 150],
        ["major", "Major", 150]
    ];

    function getRows() {
        return Array.from(
            container.querySelectorAll(".education-row")
        );
    }

    function refreshRows() {
        const rows = getRows();

        rows.forEach(function (row, index) {
            const number = row.querySelector(".row-number");

            if (number) {
                number.textContent = String(index + 1);
            }

            row.querySelectorAll("input[data-field]").forEach(function (input) {
                input.name =
                    "education[" + index + "][" + input.dataset.field + "]";
            });

            const removeButton = row.querySelector(".remove-education");

            if (removeButton) {
                removeButton.disabled = rows.length <= 1;
            }
        });

        addButton.disabled = rows.length >= MAX_ROWS;
        addButton.textContent = rows.length >= MAX_ROWS
            ? "Maximum 20 rows reached"
            : "+ Add education row";
    }

    function createRow() {
        const row = document.createElement("div");
        row.className = "education-row";

        const heading = document.createElement("h3");
        heading.appendChild(document.createTextNode("Education "));

        const number = document.createElement("span");
        number.className = "row-number";
        heading.appendChild(number);

        row.appendChild(heading);

        const grid = document.createElement("div");
        grid.className = "grid";

        fields.forEach(function (field) {
            const name = field[0];
            const labelText = field[1];
            const maxLength = field[2];

            const label = document.createElement("label");
            label.appendChild(document.createTextNode(labelText));

            const input = document.createElement("input");
            input.type = "text";
            input.maxLength = maxLength;
            input.dataset.field = name;
            input.autocomplete = "off";

            label.appendChild(input);
            grid.appendChild(label);
        });

        row.appendChild(grid);

        const removeButton = document.createElement("button");
        removeButton.type = "button";
        removeButton.className = "secondary remove-education";
        removeButton.textContent = "Remove row";

        row.appendChild(removeButton);

        return row;
    }

    // One click handler handles both existing and dynamically added buttons.
    container.addEventListener("click", function (event) {
        const button = event.target.closest(".remove-education");

        if (!button || !container.contains(button)) {
            return;
        }

        const rows = getRows();

        if (rows.length <= 1) {
            return;
        }

        button.closest(".education-row").remove();
        refreshRows();
    });

    addButton.addEventListener("click", function () {
        const rows = getRows();

        if (rows.length >= MAX_ROWS) {
            refreshRows();
            return;
        }

        container.appendChild(createRow());
        refreshRows();

        // Put keyboard focus in the new school-name field.
        const newRow = getRows().at(-1);
        const schoolInput = newRow.querySelector(
            'input[data-field="school_name"]'
        );

        if (schoolInput) {
            schoolInput.focus();
        }
    });

    refreshRows();
});
